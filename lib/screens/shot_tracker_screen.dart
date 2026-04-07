import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/shot_position.dart';
import '../utils/l10n_extension.dart';

// ── ShotTrackerScreen ─────────────────────────────────────────────────────────

class ShotTrackerScreen extends StatefulWidget {
  final int holeNumber;
  final int par;

  /// Camera opens here on launch (course / tee-box coordinates).
  final LatLng? initialPosition;

  /// Optional pin location on the green. When provided:
  ///  • "X yds to pin" chip is shown
  ///  • Camera tilt increases 0→45° as the user walks inside 150 yds of pin
  final LatLng? targetPin;

  /// Shots already recorded for this hole (e.g. when re-opening the tracker).
  /// Pre-populates markers and polyline so prior work is never lost.
  final List<ShotPosition> initialShots;

  /// Shot trails from all previously completed holes in this round.
  /// Rendered as a dimmed ghost layer so the player can see the full
  /// round trail while tracking the current hole.
  /// Each inner list is one hole's shots in order.
  final List<List<ShotPosition>> previousHolesShots;

  const ShotTrackerScreen({
    super.key,
    required this.holeNumber,
    required this.par,
    this.initialPosition,
    this.targetPin,
    this.initialShots = const [],
    this.previousHolesShots = const [],
  });

  @override
  State<ShotTrackerScreen> createState() => _ShotTrackerScreenState();
}

class _ShotTrackerScreenState extends State<ShotTrackerScreen>
    with SingleTickerProviderStateMixin {
  // ── Map ────────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // ── Shot data ──────────────────────────────────────────────────────────────
  final List<ShotPosition> _shots = [];

  // ── Follow-Me mode ─────────────────────────────────────────────────────────
  /// When true the camera tracks the user's GPS position on every tick.
  /// Automatically disabled when the user manually pans/zooms the map.
  bool _followMe = true;

  /// Set to true before every programmatic animateCamera() call so that
  /// onCameraMoveStarted can distinguish our moves from user gestures.
  bool _programmaticMove = false;

  // ── Green geofence / hole-transition prompt ─────────────────────────────────
  /// Timer that fires after the player has dwelt inside the 30-yard green zone
  /// for 2 minutes, triggering the "Ready to log putts?" bottom sheet.
  Timer? _greenDwellTimer;

  /// Guards against showing the prompt more than once per hole session.
  bool _greenPromptShown = false;

  // ── Smart-zoom velocity tracking ───────────────────────────────────────────
  /// Zoom level is driven by movement speed:
  ///   • Stationary / walking (<2.7 m/s, ~6 mph): zoom 19 — tight detail
  ///   • Jogging / slow cart (2.7–6.7 m/s):       zoom 17 — wider view
  ///   • Cart speed (>6.7 m/s, ~15 mph):           zoom 15.5 — see fairway ahead
  ///
  /// We only re-animate when the category changes to avoid jitter.
  _SpeedCategory _speedCategory = _SpeedCategory.walking;

  double _zoomForSpeed(double speedMps) {
    // Geolocator returns -1 when speed is unavailable (e.g. first fix).
    if (speedMps < 0) return 19.0;
    if (speedMps > 6.7) return 15.5; // cart
    if (speedMps > 2.7) return 17.0; // slow cart / jogging
    return 19.0;                     // walking / stationary
  }

  _SpeedCategory _categoryForSpeed(double speedMps) {
    if (speedMps < 0 || speedMps <= 2.7) return _SpeedCategory.walking;
    if (speedMps <= 6.7) return _SpeedCategory.jogging;
    return _SpeedCategory.cart;
  }

  // ── GPS ────────────────────────────────────────────────────────────────────
  /// Broadcast stream shared between StreamBuilder (UI) and the side listener
  /// (async "you are here" marker creation).
  ///
  /// Initialized synchronously in initState via an async* generator so the
  /// field is never unset when build() runs — the stream simply yields nothing
  /// until location permission is granted.
  late final Stream<Position> _posStream;
  StreamSubscription<Position>? _markerSub;

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;

  // Track whether the camera has ever been moved to an initial GPS fix,
  // so we only do it once when no initialPosition was supplied.
  bool _firstFixConsumed = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // _posStream is assigned synchronously here — the async* generator handles
    // permission internally, so build() can safely read it on the first frame.
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 2,
    );
    _posStream = _permissionGatedStream(settings).asBroadcastStream();

    // Side listener: only responsible for async "you are here" marker creation.
    // The StreamBuilder handles all synchronous UI (distance chips, camera).
    _markerSub = _posStream.listen(_onPositionForMarker);

    // Pre-populate shots from a previous session on this hole.
    if (widget.initialShots.isNotEmpty || widget.previousHolesShots.isNotEmpty) {
      _loadInitialShots();
    }
  }

  @override
  void dispose() {
    _markerSub?.cancel();
    _greenDwellTimer?.cancel();
    _pulseCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── GPS permission-gated stream ────────────────────────────────────────────

  /// Async generator: checks / requests permission, then delegates to the
  /// Geolocator stream. Returns an empty stream if permission is denied.
  Stream<Position> _permissionGatedStream(LocationSettings settings) async* {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return;
    yield* Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<void> _onPositionForMarker(Position pos) async {
    final latlng = LatLng(pos.latitude, pos.longitude);
    final myMarker = await _myLocationMarker(latlng);
    if (!mounted) return;
    setState(() {
      _markers = {
        ..._markers.where((m) => m.markerId.value != '__me__'),
        myMarker,
      };
    });
  }

  // ── Initial shot restore ───────────────────────────────────────────────────

  /// Returns the opacity for a ghost trail at [holeIndex] out of [total] holes.
  /// Most-recent hole (index = total-1) → 0.40; oldest (index 0) → 0.10.
  double _ghostOpacity(int holeIndex, int total) {
    if (total <= 1) return 0.40;
    final recency = holeIndex / (total - 1); // 0.0 = oldest, 1.0 = most recent
    return (0.10 + recency * 0.30).clamp(0.10, 0.40);
  }

  /// Rebuilds markers + polylines from saved shots when the tracker opens.
  ///
  /// Two layers are built:
  ///  1. **Ghost layer** — previous holes' trails with distance-based alpha:
  ///     most-recent hole at 40% opacity, oldest at 10%.
  ///  2. **Current hole layer** — [widget.initialShots] re-drawn as normal
  ///     green numbered pins so prior work on this hole is preserved.
  Future<void> _loadInitialShots() async {
    final newMarkers = <Marker>{};
    final newPolylines = <Polyline>{};
    final total = widget.previousHolesShots.length;

    // ── 1. Ghost layer: previous holes with fading opacity ────────────────
    for (var holeIndex = 0; holeIndex < total; holeIndex++) {
      final holeShots = widget.previousHolesShots[holeIndex];
      if (holeShots.isEmpty) continue;

      final opacity = _ghostOpacity(holeIndex, total);

      for (final s in holeShots) {
        final icon = await _ghostMarker(opacity);
        newMarkers.add(Marker(
          markerId: MarkerId('prev_h${holeIndex}_s${s.shotNumber}'),
          position: LatLng(s.lat, s.lng),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 0, // beneath current-hole markers
        ));
      }

      if (holeShots.length >= 2) {
        newPolylines.add(Polyline(
          polylineId: PolylineId('prev_trail_$holeIndex'),
          points: holeShots.map((s) => LatLng(s.lat, s.lng)).toList(),
          color: Colors.white.withValues(alpha: opacity * 0.85),
          width: 2,
          patterns: [PatternItem.dash(10), PatternItem.gap(6)],
        ));
      }
    }

    // ── 2. Current hole: restore existing shots ───────────────────────────
    for (final s in widget.initialShots) {
      final icon = s.shotNumber == 1
          ? await _teeMarker()
          : await _numberedMarker(s.shotNumber - 1);
      newMarkers.add(Marker(
        markerId: MarkerId('shot_${s.shotNumber}'),
        position: LatLng(s.lat, s.lng),
        icon: icon,
        anchor: const Offset(0.5, 1.18),
        zIndexInt: s.shotNumber,
      ));
    }

    if (!mounted) return;
    setState(() {
      _shots.addAll(widget.initialShots);
      _markers = {..._markers, ...newMarkers};
      _polylines = {..._polylines, ...newPolylines};
      _updatePolyline(); // adds current-hole trail if ≥2 shots
    });

    // Fit camera to current-hole shots when re-opening; fall back to all
    // shots (including ghost layer) if the current hole has none yet.
    final focalShots = widget.initialShots.isNotEmpty
        ? widget.initialShots
        : widget.previousHolesShots.expand((h) => h).toList();

    if (_mapController != null && focalShots.length > 1) {
      final lats = focalShots.map((s) => s.lat);
      final lngs = focalShots.map((s) => s.lng);
      final bounds = LatLngBounds(
        southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
        northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
      );
      _programmaticMove = true;
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    }
  }

  // ── Camera follow logic ────────────────────────────────────────────────────

  /// Animates the camera when Follow-Me is active.
  ///
  /// Applies two dynamic adjustments per GPS tick:
  ///  • **Tilt ramp**: 0°→45° as the user enters 150 yds of the pin.
  ///  • **Velocity zoom**: zoom 19 (walking) → 15.5 (cart speed), only
  ///    re-animated when the speed *category* changes to avoid jitter.
  void _followCamera(Position pos) {
    if (_mapController == null) return;

    final isFirstFix = !_firstFixConsumed && widget.initialPosition == null;
    if (!_followMe && !isFirstFix) return;

    if (isFirstFix) _firstFixConsumed = true;

    // ── Tilt ramp ─────────────────────────────────────────────────────────
    double tilt = 30.0;
    if (widget.targetPin != null) {
      final distMetres = Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        widget.targetPin!.latitude, widget.targetPin!.longitude,
      );
      final distYards = distMetres / 0.9144;
      const rampStart = 150.0;
      tilt = distYards < rampStart
          ? ((rampStart - distYards) / rampStart * 45.0).clamp(0.0, 45.0)
          : 0.0;
    }

    // ── Velocity zoom ─────────────────────────────────────────────────────
    final newCategory = _categoryForSpeed(pos.speed);
    final zoom = _zoomForSpeed(pos.speed);

    // Only trigger a full animateCamera when category changes; on every other
    // tick just let the ongoing animation run (avoids constant jitter).
    final categoryChanged = newCategory != _speedCategory;
    if (categoryChanged) _speedCategory = newCategory;

    if (!categoryChanged && !isFirstFix && !_followMe) return;

    _programmaticMove = true;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(pos.latitude, pos.longitude),
        zoom: zoom,
        tilt: tilt,
      )),
    );
  }

  // ── Green geofence ─────────────────────────────────────────────────────────

  /// Called on every GPS tick. Starts a 2-minute dwell timer when the player
  /// enters the 30-yard green zone; cancels it if they leave. Fires the
  /// hole-transition prompt on expiry.
  void _checkGreenGeofence(Position pos) {
    if (widget.targetPin == null || _greenPromptShown) return;

    final distMetres = Geolocator.distanceBetween(
      pos.latitude, pos.longitude,
      widget.targetPin!.latitude, widget.targetPin!.longitude,
    );
    final distYards = distMetres / 0.9144;

    if (distYards <= 30) {
      // Inside green zone — start the dwell timer if not already running.
      _greenDwellTimer ??= Timer(
        const Duration(minutes: 2),
        _onGreenDwellComplete,
      );
    } else {
      // Outside green zone — cancel any pending timer.
      _greenDwellTimer?.cancel();
      _greenDwellTimer = null;
    }
  }

  void _onGreenDwellComplete() {
    if (!mounted || _greenPromptShown) return;
    _greenPromptShown = true;

    // Subtle haptic pulse to attract attention without interrupting play.
    HapticFeedback.mediumImpact();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => _GreenArrivalSheet(
        holeNumber: widget.holeNumber,
        shotCount: _shots.length - 1,
        onFinish: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context, _shots.isEmpty ? null : List.of(_shots));
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  // ── Marker builders ────────────────────────────────────────────────────────

  Future<Marker> _myLocationMarker(LatLng pos) async {
    const size = 36.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // Outer pulse ring
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0xFF4285F4).withValues(alpha: 0.25),
    );
    // White border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 4,
      Paint()..color = Colors.white,
    );
    // Blue fill
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 4 - 2,
      Paint()..color = const Color(0xFF4285F4),
    );

    final img =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return Marker(
      markerId: const MarkerId('__me__'),
      position: pos,
      icon: BitmapDescriptor.bytes(bytes!.buffer.asUint8List()),
      anchor: const Offset(0.5, 0.5),
      zIndexInt: 0,
    );
  }

  /// Small semi-transparent white circle for previous-hole ghost markers.
  /// [opacity] controls fill alpha; outline is drawn at opacity + 0.25 so
  /// markers remain legible even at low opacity.
  Future<BitmapDescriptor> _ghostMarker([double opacity = 0.40]) async {
    const size = 24.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // Filled circle
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 1,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    // Thin outline — always slightly brighter than fill for legibility
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 1,
      Paint()
        ..color = Colors.white.withValues(alpha: (opacity + 0.25).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final img =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Blue pin with "T" label — marks the tee (first tap on the map).
  Future<BitmapDescriptor> _teeMarker() async {
    const size = 64.0;
    const teeColor = Color(0xFF1565C0); // royal blue
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size + 12));

    // Shadow
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 2),
      size / 2 - 4,
      Paint()..color = Colors.black.withValues(alpha: 0.30),
    );
    // Fill
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 4,
      Paint()..color = teeColor,
    );
    // White border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // "T" text
    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 24.0,
      fontWeight: ui.FontWeight.w800,
    ))
      ..pushStyle(ui.TextStyle(color: Colors.white))
      ..addText('T');
    final para = pb.build()..layout(const ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(para, Offset(0, (size - para.height) / 2 - 1));
    // Pointer triangle
    final triPath = Path()
      ..moveTo(size / 2 - 6, size - 4)
      ..lineTo(size / 2, size + 8)
      ..lineTo(size / 2 + 6, size - 4)
      ..close();
    canvas.drawPath(triPath, Paint()..color = teeColor);

    final img2 = await recorder
        .endRecording()
        .toImage(size.toInt(), (size + 12).toInt());
    final bytes2 = await img2.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes2!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _numberedMarker(int n) async {
    const size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size + 12));

    // Shadow
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 2),
      size / 2 - 4,
      Paint()..color = Colors.black.withValues(alpha: 0.30),
    );

    final baseGreen = n == 1
        ? const Color(0xFF1A3A08)
        : Color.lerp(
            const Color(0xFF3D6E14), const Color(0xFF5A9E1F), (n - 1) / 10.0)!;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 4,
        Paint()..color = baseGreen);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: n >= 10 ? 18.0 : 22.0,
      fontWeight: ui.FontWeight.w700,
    ))
      ..pushStyle(ui.TextStyle(color: Colors.white))
      ..addText('$n');
    final para = pb.build()..layout(const ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(para, Offset(0, (size - para.height) / 2 - 1));

    // Pointer triangle
    final triPath = Path()
      ..moveTo(size / 2 - 6, size - 4)
      ..lineTo(size / 2, size + 8)
      ..lineTo(size / 2 + 6, size - 4)
      ..close();
    canvas.drawPath(triPath, Paint()..color = baseGreen);

    final img = await recorder
        .endRecording()
        .toImage(size.toInt(), (size + 12).toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ── Shot management ────────────────────────────────────────────────────────

  Future<void> _addShot(LatLng tapped) async {
    final shotNum = _shots.length + 1;
    final shot = ShotPosition(
      shotNumber: shotNum,
      lat: tapped.latitude,
      lng: tapped.longitude,
    );
    // shotNumber 1 = tee (blue "T" pin); 2+ = numbered shots 1, 2, 3…
    final icon = shotNum == 1
        ? await _teeMarker()
        : await _numberedMarker(shotNum - 1);
    if (!mounted) return;
    setState(() {
      _shots.add(shot);
      _markers = {
        ..._markers,
        Marker(
          markerId: MarkerId('shot_$shotNum'),
          position: tapped,
          icon: icon,
          anchor: const Offset(0.5, 1.18),
          zIndexInt: shotNum,
        ),
      };
      _updatePolyline();
    });
  }

  void _undoLastShot() {
    if (_shots.isEmpty) return;
    final last = _shots.last;
    setState(() {
      _shots.removeLast();
      _markers = _markers
          .where((m) => m.markerId.value != 'shot_${last.shotNumber}')
          .toSet();
      _updatePolyline();
    });
  }

  void _updatePolyline() {
    if (_shots.length < 2) {
      _polylines = {};
      return;
    }
    _polylines = {
      Polyline(
        polylineId: const PolylineId('trail'),
        points: _shots.map((s) => LatLng(s.lat, s.lng)).toList(),
        color: const Color(0xFF5A9E1F),
        width: 3,
        patterns: [PatternItem.dash(16), PatternItem.gap(8)],
      ),
    };
  }

  // ── Distance helpers ───────────────────────────────────────────────────────

  /// Distance between the last two dropped markers (shot-to-shot).
  int? _lastShotYards() {
    if (_shots.length < 2) return null;
    final a = _shots[_shots.length - 2];
    final b = _shots.last;
    final metres =
        Geolocator.distanceBetween(a.lat, a.lng, b.lat, b.lng);
    return (metres / 0.9144).round();
  }

  /// Distance from [pos] to [targetPin].
  int? _pinYards(Position pos) {
    if (widget.targetPin == null) return null;
    final metres = Geolocator.distanceBetween(
      pos.latitude, pos.longitude,
      widget.targetPin!.latitude, widget.targetPin!.longitude,
    );
    return (metres / 0.9144).round();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final safePad = MediaQuery.of(context).padding;
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    // StreamBuilder drives all GPS-dependent UI with zero-lag reactivity.
    // No setState needed here — the stream itself rebuilds the widget.
    return StreamBuilder<Position>(
      stream: _posStream,
      builder: (context, snapshot) {
        final pos = snapshot.data;

        // Side-effects inside StreamBuilder (no setState required):
        if (pos != null) {
          _followCamera(pos);
          _checkGreenGeofence(pos);
        }

        final pinYds = pos != null ? _pinYards(pos) : null;
        final lastShotYds = _lastShotYards();
        final hasGps = pos != null;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ── Full-screen satellite map ───────────────────────────────
              GoogleMap(
                mapType: MapType.hybrid,
                initialCameraPosition: CameraPosition(
                  target: widget.initialPosition ?? const LatLng(20, 0),
                  zoom: widget.initialPosition != null ? 19.0 : 2.0,
                  tilt: widget.initialPosition != null ? 30.0 : 0.0,
                ),
                markers: _markers,
                polylines: _polylines,
                onTap: _addShot,
                onMapCreated: (ctrl) => _mapController = ctrl,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                // Detect user-initiated pans — disable follow so they can
                // look around freely without the camera snapping back.
                onCameraMoveStarted: () {
                  if (!_programmaticMove && _followMe) {
                    setState(() => _followMe = false);
                  }
                },
                // Reset the programmatic-move guard once the animation settles.
                onCameraIdle: () => _programmaticMove = false,
              ),

              // ── Top gradient header ─────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      EdgeInsets.fromLTRB(16, safePad.top + 8, 16, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hole ${widget.holeNumber}  ·  Par ${widget.par}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: body * 1.05,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            Text(
                              _shots.isEmpty
                                  ? context.l10n.shotTrackerTapToMark
                                  : _shots.length == 1
                                      ? context.l10n.shotTrackerTeeMarked
                                      : context.l10n.shotTrackerShotsFromTee(_shots.length - 1),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: label,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_shots.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A9E1F),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '${_shots.length - 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Distance chips ──────────────────────────────────────────
              // Rendered directly from StreamBuilder snapshot — no setState.
              if (pinYds != null || lastShotYds != null)
                Positioned(
                  bottom: safePad.bottom + 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        // Distance to pin (when targetPin provided)
                        if (pinYds != null)
                          _distanceChip(
                            icon: Icons.flag_rounded,
                            iconColor: const Color(0xFFFFCC00),
                            label: context.l10n.shotTrackerDistToPin('$pinYds'),
                          ),
                        // Distance of the last shot (between last 2 markers)
                        if (lastShotYds != null)
                          _distanceChip(
                            icon: Icons.straighten_rounded,
                            iconColor: Colors.white,
                            label: context.l10n.shotTrackerLastShot('$lastShotYds'),
                          ),
                      ],
                    ),
                  ),
                ),

              // ── Follow-Me button ───────────────────────────────────────
              // Shown when GPS is available. Glows blue when active, dim when
              // the user has panned away. Tap to re-engage follow mode.
              if (hasGps)
                Positioned(
                  right: 16,
                  bottom: safePad.bottom + 80,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _followMe = true);
                      // Immediately snap to current position on re-engage.
                      _followCamera(pos);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _followMe
                            ? const Color(0xFF4285F4)
                            : Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _followMe
                              ? Colors.white.withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.20),
                          width: 1.5,
                        ),
                        boxShadow: _followMe
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4285F4)
                                      .withValues(alpha: 0.50),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        _followMe
                            ? Icons.navigation_rounded
                            : Icons.navigation_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              // ── Bottom action bar ───────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      20, 12, 20, safePad.bottom + 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.80),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Undo last shot
                      GestureDetector(
                        onTap: _shots.isEmpty ? null : _undoLastShot,
                        child: AnimatedOpacity(
                          opacity: _shots.isEmpty ? 0.35 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.undo_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n.shotTrackerUndo,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: body,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Finish hole / Done
                      GestureDetector(
                        onTap: () => Navigator.pop(
                            context,
                            _shots.isEmpty ? null : List.of(_shots)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: _shots.isEmpty
                                ? Colors.white.withValues(alpha: 0.20)
                                : const Color(0xFF5A9E1F),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: _shots.isNotEmpty
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF5A9E1F)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _shots.isEmpty
                                    ? context.l10n.shotTrackerFinishHole
                                    : context.l10n.shotTrackerFinishHoleWithCount(_shots.length - 1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: body,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Acquiring GPS hint ──────────────────────────────────────
              if (!hasGps && widget.initialPosition == null)
                Positioned(
                  top: safePad.top + 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.60),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingDot(color: const Color(0xFF4285F4)),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.shotTrackerAcquiringGPS,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Shared chip widget ─────────────────────────────────────────────────────

  Widget _distanceChip({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Speed category enum ───────────────────────────────────────────────────────

enum _SpeedCategory { walking, jogging, cart }

// ── Pulsing dot indicator ─────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, w) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.4 + _ctrl.value * 0.6),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _ctrl.value * 0.5),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Green arrival bottom sheet ────────────────────────────────────────────────

class _GreenArrivalSheet extends StatelessWidget {
  final int holeNumber;
  final int shotCount;
  final VoidCallback onFinish;
  final VoidCallback onDismiss;

  const _GreenArrivalSheet({
    required this.holeNumber,
    required this.shotCount,
    required this.onFinish,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final safePad = MediaQuery.of(context).padding;
    final body = (sw * 0.038).clamp(14.0, 17.0);
    final label = (sw * 0.032).clamp(12.0, 14.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, safePad.bottom + 8),
      decoration: BoxDecoration(
        // Dark frosted card that reads on top of the satellite map.
        color: const Color(0xFF1C2A1C).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF5A9E1F).withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Flag icon + headline
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A9E1F).withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded,
                    color: Color(0xFF5A9E1F), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.shotTrackerNiceApproach,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: body * 1.1,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      context.l10n.shotTrackerOnGreen(
                        shotCount > 0
                            ? '$shotCount shot${shotCount == 1 ? '' : 's'} tracked. '
                            : '',
                        holeNumber,
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: label,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              // Not yet
              Expanded(
                child: GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      context.l10n.shotTrackerNotYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: label,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Log putts
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onFinish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A9E1F),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5A9E1F)
                              .withValues(alpha: 0.40),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      context.l10n.shotTrackerLogPutts(holeNumber),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: label,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Static trail map (used in Round Detail bottom sheet) ─────────────────────

/// Read-only satellite map of a recorded shot trail.
/// Fits the camera to show all shots automatically.
class ShotTrailMapView extends StatefulWidget {
  final List<ShotPosition> shots;
  final int holeNumber;

  const ShotTrailMapView({
    super.key,
    required this.shots,
    required this.holeNumber,
  });

  @override
  State<ShotTrailMapView> createState() => _ShotTrailMapViewState();
}

class _ShotTrailMapViewState extends State<ShotTrailMapView> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _markersReady = false;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  Future<void> _buildMarkers() async {
    final markers = <Marker>{};
    for (final s in widget.shots) {
      // shotNumber 1 = tee (blue "T"), 2+ = numbered shots starting at 1
      final icon = s.shotNumber == 1
          ? await _teeMarker()
          : await _numberedMarker(s.shotNumber - 1);
      markers.add(Marker(
        markerId: MarkerId('trail_${s.shotNumber}'),
        position: LatLng(s.lat, s.lng),
        icon: icon,
        anchor: const Offset(0.5, 1.18),
        zIndexInt: s.shotNumber,
      ));
    }
    if (!mounted) return;
    setState(() {
      _markers.addAll(markers);
      if (widget.shots.length >= 2) {
        _polylines.add(Polyline(
          polylineId: const PolylineId('trail'),
          points: widget.shots.map((s) => LatLng(s.lat, s.lng)).toList(),
          color: const Color(0xFF5A9E1F),
          width: 3,
          patterns: [PatternItem.dash(16), PatternItem.gap(8)],
        ));
      }
      _markersReady = true;
    });
  }

  Future<BitmapDescriptor> _teeMarker() async {
    const size = 56.0;
    const teeColor = Color(0xFF1565C0);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size + 10));

    canvas.drawCircle(const Offset(size / 2, size / 2 + 2), size / 2 - 3,
        Paint()..color = Colors.black.withValues(alpha: 0.25));
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 3,
        Paint()..color = teeColor);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 3,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 20.0,
      fontWeight: ui.FontWeight.w800,
    ))
      ..pushStyle(ui.TextStyle(color: Colors.white))
      ..addText('T');
    final para = pb.build()..layout(ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(para, Offset(0, (size - para.height) / 2 - 1));
    final tri = Path()
      ..moveTo(size / 2 - 5, size - 3)
      ..lineTo(size / 2, size + 7)
      ..lineTo(size / 2 + 5, size - 3)
      ..close();
    canvas.drawPath(tri, Paint()..color = teeColor);

    final img = await recorder
        .endRecording()
        .toImage(size.toInt(), (size + 10).toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _numberedMarker(int n) async {
    const size = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size + 10));

    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 2),
      size / 2 - 3,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    final green = Color.lerp(
        const Color(0xFF1A3A08), const Color(0xFF5A9E1F), (n - 1) / 10.0)!;
    canvas.drawCircle(
        const Offset(size / 2, size / 2), size / 2 - 3, Paint()..color = green);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 3,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: n >= 10 ? 16.0 : 20.0,
      fontWeight: ui.FontWeight.w700,
    ))
      ..pushStyle(ui.TextStyle(color: Colors.white))
      ..addText('$n');
    final para = pb.build()..layout(ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(para, Offset(0, (size - para.height) / 2 - 1));

    final triPath = Path()
      ..moveTo(size / 2 - 5, size - 3)
      ..lineTo(size / 2, size + 7)
      ..lineTo(size / 2 + 5, size - 3)
      ..close();
    canvas.drawPath(triPath, Paint()..color = green);

    final img = await recorder
        .endRecording()
        .toImage(size.toInt(), (size + 10).toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  LatLngBounds _computeBounds() {
    final lats = widget.shots.map((s) => s.lat);
    final lngs = widget.shots.map((s) => s.lng);
    return LatLngBounds(
      southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
      northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shots.isEmpty) return const SizedBox.shrink();
    final first = widget.shots.first;
    return GoogleMap(
      mapType: MapType.hybrid,
      initialCameraPosition: CameraPosition(
        target: LatLng(first.lat, first.lng),
        zoom: 17.5,
      ),
      markers: _markers,
      polylines: _polylines,
      zoomControlsEnabled: false,
      myLocationEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      onMapCreated: (ctrl) {
        if (_markersReady && widget.shots.length > 1) {
          Future.delayed(const Duration(milliseconds: 300), () {
            ctrl.animateCamera(
              CameraUpdate.newLatLngBounds(_computeBounds(), 60),
            );
          });
        }
      },
    );
  }
}
