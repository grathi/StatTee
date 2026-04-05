import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/round.dart';
import '../services/places_service.dart';
import '../services/round_service.dart';
import '../theme/app_theme.dart';
import 'round_detail_screen.dart';

// ---------------------------------------------------------------------------
// GolfWorldMap — satellite map showing every round played as a glassmorphic
// marker card, with animated camera and a bottom-sheet round summary.
// ---------------------------------------------------------------------------

class _PlacedRound {
  final Round round;
  final double lat;
  final double lng;
  final String geoLabel;

  const _PlacedRound({
    required this.round,
    required this.lat,
    required this.lng,
    required this.geoLabel,
  });
}

class GolfWorldMap extends StatefulWidget {
  const GolfWorldMap({super.key});

  @override
  State<GolfWorldMap> createState() => _GolfWorldMapState();
}

class _GolfWorldMapState extends State<GolfWorldMap>
    with SingleTickerProviderStateMixin {
  // Map
  GoogleMapController? _mapController;

  // Fly-to animation
  AnimationController? _flyController;
  final Set<Marker> _markers = {};

  // Data
  StreamSubscription<List<Round>>? _sub;
  List<_PlacedRound> _placedRounds = [];
  final Map<String, ({double lat, double lng, String label})> _geoCache = {};
  bool _geocoding = false;
  bool _mapReady = false;

  // Marker rendering
  final Map<String, GlobalKey> _markerKeys = {};
  final Map<String, Uint8List> _markerImageCache = {};

  // Search
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // ── Computed ──────────────────────────────────────────────────────────────

  List<_PlacedRound> get _filtered {
    if (_searchQuery.trim().isEmpty) return _placedRounds;
    final q = _searchQuery.toLowerCase();
    return _placedRounds
        .where((p) =>
            p.round.courseName.toLowerCase().contains(q) ||
            p.round.courseLocation.toLowerCase().contains(q) ||
            p.geoLabel.toLowerCase().contains(q))
        .toList();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _sub = RoundService.allCompletedRoundsStream().listen(_onRounds);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _flyController?.dispose();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data pipeline ─────────────────────────────────────────────────────────

  void _onRounds(List<Round> rounds) {
    if (!mounted) return;
    _geocodeRounds(rounds);
  }

  Future<void> _geocodeRounds(List<Round> rounds) async {
    if (_geocoding) return;
    setState(() => _geocoding = true);

    // Rounds that already have GPS coords stored — use them directly.
    final withCoords = rounds.where((r) => r.lat != null && r.lng != null).toList();

    // Rounds without GPS coords — geocode their location string.
    final needsGeocode = rounds
        .where((r) => r.lat == null || r.lng == null)
        .toList();

    final uncached = needsGeocode
        .map((r) => r.courseLocation.trim())
        .where((loc) => loc.isNotEmpty && !_geoCache.containsKey(loc.toLowerCase()))
        .toSet()
        .toList();

    const chunkSize = 5;
    for (var i = 0; i < uncached.length; i += chunkSize) {
      final chunk = uncached.skip(i).take(chunkSize).toList();
      final results = await Future.wait(
        chunk.map((loc) => PlacesService.geocodeCity(loc)),
      );
      for (var j = 0; j < chunk.length; j++) {
        final r = results[j];
        if (r != null) _geoCache[chunk[j].toLowerCase()] = r;
      }
      if (i + chunkSize < uncached.length) {
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }

    final placed = <_PlacedRound>[];

    // Add GPS-precise rounds first.
    for (final round in withCoords) {
      if (round.id == null) continue;
      placed.add(_PlacedRound(
        round: round,
        lat: round.lat!,
        lng: round.lng!,
        geoLabel: round.courseLocation.isNotEmpty
            ? round.courseLocation.split(',').take(2).join(',').trim()
            : round.courseName,
      ));
    }

    // Add geocoded rounds (fallback for old data).
    for (final round in needsGeocode) {
      if (round.id == null) continue;
      final key = round.courseLocation.trim().toLowerCase();
      final geo = _geoCache[key];
      if (geo != null) {
        placed.add(_PlacedRound(
          round: round,
          lat: geo.lat,
          lng: geo.lng,
          geoLabel: geo.label,
        ));
      }
    }

    // Sort by most recent first so _placedRounds.first == latest round.
    placed.sort((a, b) => b.round.startedAt.compareTo(a.round.startedAt));

    if (!mounted) return;
    setState(() {
      _placedRounds = placed;
      _geocoding = false;
      for (final p in placed) {
        _markerKeys.putIfAbsent(p.round.id!, () => GlobalKey());
      }
    });

    if (_mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _renderAndPlaceMarkers();
        _flyToLastPlayed();
      });
    }
  }

  void _flyToLastPlayed() {
    if (_placedRounds.isEmpty || _mapController == null) return;
    final last = _placedRounds.first;

    // Start position (initial map camera)
    const startLat = 20.0;
    const startLng = 0.0;
    const startZoom = 2.0;
    const startTilt = 0.0;

    // End position
    final endLat = last.lat;
    final endLng = last.lng;
    const endZoom = 11.0;
    const endTilt = 30.0;

    _flyController?.dispose();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    final anim = CurvedAnimation(
      parent: _flyController!,
      curve: Curves.easeInOutCubic,
    );

    anim.addListener(() {
      final t = anim.value;
      _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(
            startLat + (endLat - startLat) * t,
            startLng + (endLng - startLng) * t,
          ),
          zoom: startZoom + (endZoom - startZoom) * t,
          tilt: startTilt + (endTilt - startTilt) * t,
          bearing: 0,
        )),
      );
    });

    _flyController!.forward();
  }

  // ── Marker rendering ──────────────────────────────────────────────────────

  Future<void> _renderAndPlaceMarkers() async {
    for (final p in _filtered) {
      final id = p.round.id!;
      if (_markerImageCache.containsKey(id)) continue;
      final bytes = await _renderMarker(id);
      if (bytes != null) _markerImageCache[id] = bytes;
    }
    _placeMarkers();
  }

  Future<Uint8List?> _renderMarker(String roundId) async {
    final key = _markerKeys[roundId];
    if (key?.currentContext == null) return null;

    RenderRepaintBoundary? boundary;
    for (int attempt = 0; attempt < 5; attempt++) {
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
      await completer.future;

      if (key?.currentContext == null) return null;
      boundary = key!.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null && !boundary.debugNeedsPaint) break;
      boundary = null;
    }
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _placeMarkers() {
    final newMarkers = <Marker>{};
    for (final p in _filtered) {
      final bytes = _markerImageCache[p.round.id!];
      if (bytes == null) continue;
      newMarkers.add(Marker(
        markerId: MarkerId(p.round.id!),
        position: LatLng(p.lat, p.lng),
        icon: BitmapDescriptor.bytes(bytes),
        anchor: const Offset(0.5, 1.0),
        onTap: () => _onMarkerTap(p),
      ));
    }
    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(newMarkers);
      });
    }
  }

  // ── Map events ────────────────────────────────────────────────────────────

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() => _mapReady = true);
    if (_placedRounds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _renderAndPlaceMarkers();
        _flyToLastPlayed();
      });
    }
  }

  void _onMarkerTap(_PlacedRound placed) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(placed.lat, placed.lng),
        zoom: 15.5,
        tilt: 45.0,
        bearing: 0,
      )),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _showRoundSheet(placed);
    });
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    WidgetsBinding.instance.addPostFrameCallback((_) => _placeMarkers());
  }

  // ── Stats chip helpers ────────────────────────────────────────────────────

  Widget _statPill(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF5A9E1F), size: 14),
        const SizedBox(width: 5),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 10,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white.withValues(alpha: 0.15),
      );

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  void _showRoundSheet(_PlacedRound placed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RoundSummarySheet(placed: placed)
          .animate()
          .slideY(begin: 1.0, end: 0.0, duration: 380.ms, curve: Curves.easeOutCubic),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      extendBody: true,
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              mapType: MapType.satellite,
              initialCameraPosition: const CameraPosition(
                target: LatLng(20, 0),
                zoom: 2.0,
                tilt: 0,
              ),
              markers: _markers,
              onMapCreated: _onMapCreated,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
            ),
          ),

          // ── Off-screen marker render layer ─────────────────────────────────
          // Positioned far off-screen so widgets actually paint.
          Positioned(
            top: -9999,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_placedRounds.length, (i) {
                final p = _placedRounds[i];
                final key = _markerKeys[p.round.id!];
                if (key == null) return const SizedBox.shrink();
                return RepaintBoundary(
                  key: key,
                  child: _GlassmorphicMarker(
                    score: p.round.totalScore,
                    scoreDiff: p.round.scoreDiff,
                    courseName: p.round.courseName,
                    isRecent: i == 0,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Back button ────────────────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),

          // ── Floating search bar ────────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 68,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Nunito',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search Courses Played',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 14,
                        fontFamily: 'Nunito',
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.55), size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Geocoding indicator ────────────────────────────────────────────
          if (_geocoding)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF5A9E1F),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Mapping your courses…',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Stats chip ────────────────────────────────────────────────────
          if (!_geocoding && _placedRounds.isNotEmpty)
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statPill(
                        Icons.flag_rounded,
                        '${_filtered.length}',
                        _filtered.length == 1 ? 'course' : 'courses',
                      ),
                      _statDivider(),
                      _statPill(
                        Icons.sports_golf_rounded,
                        '${_placedRounds.length}',
                        _placedRounds.length == 1 ? 'round' : 'rounds',
                      ),
                      _statDivider(),
                      _statPill(
                        Icons.emoji_events_rounded,
                        _placedRounds.map((p) => p.round.totalScore).reduce((a, b) => a < b ? a : b).toString(),
                        'best',
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Glassmorphic marker widget ────────────────────────────────────────────────

class _GlassmorphicMarker extends StatelessWidget {
  final int score;
  final int scoreDiff;
  final String courseName;
  final bool isRecent;

  const _GlassmorphicMarker({
    required this.score,
    required this.scoreDiff,
    required this.courseName,
    this.isRecent = false,
  });

  Color get _diffColor {
    if (scoreDiff <= -2) return const Color(0xFFFFD700);
    if (scoreDiff == -1) return const Color(0xFF4CAF82);
    if (scoreDiff == 0) return const Color(0xFF64B5F6);
    if (scoreDiff == 1) return const Color(0xFFFFB74D);
    return const Color(0xFFFF6B6B);
  }

  String get _diffLabel =>
      scoreDiff == 0 ? 'E' : scoreDiff > 0 ? '+$scoreDiff' : '$scoreDiff';

  // Truncate course name to fit the card width
  String get _shortName {
    final parts = courseName.split(' ');
    // Drop generic suffixes for brevity
    final filtered = parts.where((w) =>
        !['Golf', 'Club', 'Course', 'Country', 'Links'].contains(w)).toList();
    final name = (filtered.isEmpty ? parts : filtered).join(' ');
    return name.length > 14 ? '${name.substring(0, 13)}…' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.1),
      alignment: Alignment.center,
      child: SizedBox(
        width: 88,
        height: 60,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Recent glow ring
            if (isRecent)
              Positioned(
                top: -3,
                left: -3,
                right: -3,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF5A9E1F),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A9E1F).withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

            // Card body
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.92),
                      Colors.white.withValues(alpha: 0.78),
                    ],
                  ),
                  border: Border.all(
                    color: isRecent
                        ? const Color(0xFF5A9E1F).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.90),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0xFF1A3A08).withValues(alpha: 0.80),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.golf_course_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Course name
                          Text(
                            _shortName,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              color: Color(0xFF0F172A),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '$score',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Color(0xFF0F172A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _diffLabel,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: _diffColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pointer triangle
            Positioned(
              bottom: 0,
              child: CustomPaint(
                size: const Size(12, 8),
                painter: _PointerPainter(
                  color: isRecent
                      ? const Color(0xFF5A9E1F).withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _RoundSummarySheet extends StatelessWidget {
  final _PlacedRound placed;

  const _RoundSummarySheet({required this.placed});

  Color _diffColor(int d) {
    if (d <= -2) return const Color(0xFFFFD700);
    if (d == -1) return const Color(0xFF4CAF82);
    if (d == 0) return const Color(0xFF64B5F6);
    if (d == 1) return const Color(0xFFFFB74D);
    return const Color(0xFFFF6B6B);
  }

  String _diffLabel(int d) =>
      d == 0 ? 'E' : d > 0 ? '+$d' : '$d';

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[dt.month]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final round = placed.round;
    final diff = round.scoreDiff;
    final diffColor = _diffColor(diff);
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: colors.cardBorder),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.paddingOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            round.courseName,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.15, end: 0),

          const SizedBox(height: 4),

          Text(
            '${placed.geoLabel}  ·  ${_formatDate(round.completedAt)}',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 13,
              fontFamily: 'Nunito',
            ),
          ).animate(delay: 40.ms).fadeIn(duration: 240.ms).slideY(begin: 0.15, end: 0),

          const SizedBox(height: 18),

          Row(
            children: [
              Text(
                '${round.totalScore}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: colors.primaryText,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: ShapeDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: diffColor.withValues(alpha: 0.40), width: 1.2),
                  ),
                ),
                child: Text(
                  _diffLabel(diff),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: diffColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ).animate(delay: 80.ms).fadeIn(duration: 240.ms).slideY(begin: 0.15, end: 0),

          const SizedBox(height: 18),

          Row(
            children: [
              _stat(context, 'Putts', '${round.totalPutts}', delay: 120),
              _stat(context, 'Birdies', '${round.birdies}', delay: 160),
              _stat(context, 'Fairways',
                  '${round.fairwaysHitPct.toStringAsFixed(0)}%',
                  delay: 200),
              _stat(context, 'GIR',
                  '${round.girPct.toStringAsFixed(0)}%',
                  delay: 240),
            ],
          ),

          const SizedBox(height: 22),

          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => RoundDetailScreen(round: round)),
              );
            },
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: colors.accentBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.accentBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                'View Scorecard',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: colors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ).animate(delay: 280.ms).fadeIn(duration: 240.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, {int delay = 0}) {
    final colors = AppColors.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.accentBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Nunito',
                color: colors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                color: colors.secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: delay))
          .fadeIn(duration: 220.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}
