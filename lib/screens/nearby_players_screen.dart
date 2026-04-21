import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/join_request.dart';
import '../models/user_session.dart';
import '../services/nearby_players_service.dart';
import '../services/places_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';
import 'start_round_screen.dart';

class NearbyPlayersScreen extends StatefulWidget {
  const NearbyPlayersScreen({
    super.key,
    required this.c,
    required this.sw,
    required this.sh,
    required this.hPad,
    required this.body,
    required this.label,
  });

  final AppColors c;
  final double sw, sh, hPad, body, label;

  @override
  State<NearbyPlayersScreen> createState() => _NearbyPlayersScreenState();
}

class _NearbyPlayersScreenState extends State<NearbyPlayersScreen>
    with WidgetsBindingObserver {
  // ── State ──────────────────────────────────────────────────────────────────

  bool _isCheckedIn = false;
  bool _isLookingForGroup = false;
  bool _isLoadingLocation = false;
  bool _isSendingRequest = false;
  GolfCourseDetail? _detectedCourse;
  Position? _lastPosition;
  Timer? _heartbeatTimer;
  String? _errorMessage;
  final Set<String> _requestSentTo = {};
  // uid → requestId, so we can cancel
  final Map<String, String> _sentRequestIds = {};
  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExistingSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    // Do NOT delete the session — user may just be switching tabs.
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isCheckedIn && _detectedCourse != null) {
        _startHeartbeat();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _heartbeatTimer?.cancel();
    }
  }

  // ── Session restore on tab re-entry ───────────────────────────────────────

  Future<void> _checkExistingSession() async {
    final session = await NearbyPlayersService.getMySession();
    if (!mounted || session == null) return;
    setState(() {
      _isCheckedIn = true;
      _isLookingForGroup = session.isLookingForGroup;
      _detectedCourse = GolfCourseDetail(
        placeId: session.currentCourseId,
        name: session.courseName,
        address: '',
        lat: session.lat,
        lng: session.lng,
      );
    });
    // Restart heartbeat with last known position from session
    _lastPosition = null; // Will refresh on next heartbeat cycle
  }

  // ── Check-in flow ──────────────────────────────────────────────────────────

  Future<void> _onCheckInTap() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      // 1. Resolve coordinates — mirror the Home screen's location strategy.
      //    Priority: Firestore saved location → last known GPS → fresh GPS.
      double? useLat;
      double? useLng;
      Position? position;
      List<GolfCourseDetail> courses = [];

      final saved = await UserProfileService.getSavedLocation();
      if (saved != null) {
        useLat = saved.lat;
        useLng = saved.lng;
        // Use the same city-search path the home screen uses for saved locations
        final result = await PlacesService.searchGolfCoursesByCity(saved.label);
        courses = result?.courses ?? [];
      } else {
        // No saved city — fall back to GPS (last known first to avoid timeout)
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever ||
            perm == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _errorMessage = context.l10n.nearbyNotAtCourse;
            });
          }
          return;
        }
        position = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
              ),
            );
        useLat = position.latitude;
        useLng = position.longitude;
        courses = await PlacesService.nearbyGolfCourses(
          position,
          lat: useLat,
          lng: useLng,
        );
      }

      // 3. Geofence check — must be within 1 km
      final nearest = NearbyPlayersService.findNearestCourse(
        useLat,
        useLng,
        courses,
      );

      if (nearest == null) {
        // No course auto-detected within 1 km — let user pick from the
        // full 25 km radius list (covers simulator + large properties).
        if (!mounted) return;
        setState(() => _isLoadingLocation = false);
        if (courses.isEmpty) {
          setState(() => _errorMessage = context.l10n.nearbyNotAtCourse);
          return;
        }
        final picked = await _showCoursePicker(courses, useLat, useLng);
        if (picked == null) return; // user dismissed
        await _checkInAt(picked, position, useLat, useLng);
        return;
      }

      await _checkInAt(nearest, position, useLat, useLng);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = context.l10n.nearbyNotAtCourse;
        });
      }
    }
  }

  // ── Check-in at a specific course ──────────────────────────────────────────

  Future<void> _checkInAt(
      GolfCourseDetail course, Position? position, double lat, double lng) async {
    await NearbyPlayersService.upsertSession(
      courseId: course.placeId,
      courseName: course.name,
      lat: lat,
      lng: lng,
      isLookingForGroup: false,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingLocation = false;
      _isCheckedIn = true;
      _isLookingForGroup = false;
      _detectedCourse = course;
      _lastPosition = position;
      _errorMessage = null;
    });

    _startHeartbeat();
  }

  // ── Course picker sheet (fallback when outside 1 km geofence) ─────────────

  Future<GolfCourseDetail?> _showCoursePicker(
      List<GolfCourseDetail> courses, double lat, double lng) {
    final c = widget.c;
    final body = widget.body;
    final label = widget.label;

    return showModalBottomSheet<GolfCourseDetail>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.fieldBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Select Your Course',
                  style: TextStyle(
                    color: c.primaryText,
                    fontSize: body * 1.1,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: courses.length,
                  itemBuilder: (_, i) {
                    final course = courses[i];
                    final dist = course.lat != null
                        ? Geolocator.distanceBetween(
                                lat, lng, course.lat!, course.lng!)
                            .round()
                        : null;
                    return GestureDetector(
                      onTap: () => Navigator.pop(ctx, course),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: ShapeDecoration(
                          color: c.fieldBg,
                          shape: SuperellipseShape(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: c.fieldBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.golf_course_rounded,
                                color: c.accent, size: body),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: c.primaryText,
                                        fontSize: body,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  if (dist != null)
                                    Text(
                                      dist < 1000
                                          ? '$dist m away'
                                          : '${(dist / 1000).toStringAsFixed(1)} km away',
                                      style: TextStyle(
                                          color: c.tertiaryText,
                                          fontSize: label),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: c.tertiaryText, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Heartbeat ──────────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (_detectedCourse == null) return;
      try {
        double lat, lng;
        if (_lastPosition != null) {
          lat = _lastPosition!.latitude;
          lng = _lastPosition!.longitude;
        } else if (_detectedCourse!.lat != null) {
          // Saved-location check-in — use the course's own coordinates.
          lat = _detectedCourse!.lat!;
          lng = _detectedCourse!.lng!;
        } else {
          return; // no coords at all — skip this tick
        }
        await NearbyPlayersService.upsertSession(
          courseId: _detectedCourse!.placeId,
          courseName: _detectedCourse!.name,
          lat: lat,
          lng: lng,
          isLookingForGroup: _isLookingForGroup,
        );
      } catch (_) {
        // Heartbeat failures are non-fatal
      }
    });
  }

  // ── Toggle looking-for-group ───────────────────────────────────────────────

  Future<void> _onLookingForGroupToggle(bool value) async {
    setState(() => _isLookingForGroup = value);
    await NearbyPlayersService.setLookingForGroup(value);
  }

  // ── Leave ─────────────────────────────────────────────────────────────────

  Future<void> _onLeave() async {
    _heartbeatTimer?.cancel();
    await NearbyPlayersService.deleteSession();
    if (mounted) {
      setState(() {
        _isCheckedIn = false;
        _isLookingForGroup = false;
        _detectedCourse = null;
        _lastPosition = null;
        _errorMessage = null;
        _requestSentTo.clear();
        _sentRequestIds.clear();
      });
    }
  }

  // ── Accept join request ────────────────────────────────────────────────────

  Future<void> _onAcceptRequest(JoinRequest request) async {
    await NearbyPlayersService.respondToRequest(request.id, true);
    if (!mounted || _detectedCourse == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartRoundScreen(
          initialCourseName: _detectedCourse!.name,
          initialCustomLat: _detectedCourse!.lat,
          initialCustomLng: _detectedCourse!.lng,
          preInvitedUid: request.fromUserId,
          preInvitedName: request.fromDisplayName,
          preInvitedAvatar: request.fromAvatarUrl,
        ),
      ),
    );
  }

  // ── Send join request ──────────────────────────────────────────────────────

  Future<void> _onSendRequest(UserSession target) async {
    if (_isSendingRequest) return;
    setState(() => _isSendingRequest = true);
    try {
      final requestId = await NearbyPlayersService.sendJoinRequest(targetSession: target);
      if (mounted) {
        setState(() {
          _requestSentTo.add(target.userId);
          if (requestId != null) _sentRequestIds[target.userId] = requestId;
        });
      }
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  // ── Cancel join request ────────────────────────────────────────────────────

  Future<void> _onCancelRequest(String targetUserId) async {
    final requestId = _sentRequestIds[targetUserId] ??
        await NearbyPlayersService.findPendingOutgoingRequest(targetUserId);
    if (requestId != null) {
      await NearbyPlayersService.cancelRequest(requestId);
    }
    if (mounted) {
      setState(() {
        _requestSentTo.remove(targetUserId);
        _sentRequestIds.remove(targetUserId);
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c     = widget.c;
    final hPad  = widget.hPad;
    final sh    = widget.sh;
    final body  = widget.body;
    final label = widget.label;

    return Column(
      children: [
        // Check-in / checked-in panel
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.012),
          child: _isCheckedIn
              ? StreamBuilder<List<JoinRequest>>(
                  stream: NearbyPlayersService.incomingRequestsStream(),
                  builder: (context, snap) {
                    final requests = snap.data ?? [];
                    return _CheckedInPanel(
                      c: c,
                      body: body,
                      label: label,
                      courseName: _detectedCourse?.name ?? '',
                      isLookingForGroup: _isLookingForGroup,
                      incomingRequests: requests,
                      onToggle: _onLookingForGroupToggle,
                      onLeave: _onLeave,
                      onAccept: _onAcceptRequest,
                      onDecline: (id) =>
                          NearbyPlayersService.respondToRequest(id, false),
                    );
                  },
                )
              : _CheckInPanel(
                  c: c,
                  body: body,
                  label: label,
                  isLoading: _isLoadingLocation,
                  errorMessage: _errorMessage,
                  onCheckIn: _onCheckInTap,
                ),
        ),

        // Discovery area
        if (_isCheckedIn)
          Expanded(
            child: _isLookingForGroup
                ? _DiscoveryList(
                    c: c,
                    body: body,
                    label: label,
                    hPad: hPad,
                    sh: sh,
                    courseId: _detectedCourse!.placeId,
                    requestSentTo: _requestSentTo,
                    onSendRequest: _onSendRequest,
                    onCancelRequest: _onCancelRequest,
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_off_outlined,
                            size: 48, color: c.tertiaryText),
                        const SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          child: Text(
                            context.l10n.nearbyTogglePrompt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: c.secondaryText,
                              fontSize: body * 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
      ],
    );
  }
}

// ── Check-in panel (not yet checked in) ──────────────────────────────────────

class _CheckInPanel extends StatelessWidget {
  const _CheckInPanel({
    required this.c,
    required this.body,
    required this.label,
    required this.isLoading,
    required this.errorMessage,
    required this.onCheckIn,
  });

  final AppColors c;
  final double body, label;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: ShapeDecoration(
                  color: c.accentBg,
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Icon(Icons.location_on_rounded,
                    color: c.accent, size: body * 1.3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.nearbyCheckInTitle,
                        style: TextStyle(
                          color: c.primaryText,
                          fontSize: body,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 3),
                    Text(context.l10n.nearbyCheckInBody,
                        style: TextStyle(
                          color: c.tertiaryText,
                          fontSize: label,
                        )),
                  ],
                ),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(errorMessage!,
                style: TextStyle(
                    color: Colors.red.shade400, fontSize: label)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: isLoading ? null : onCheckIn,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: ShapeDecoration(
                  gradient: isLoading
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)]),
                  color: isLoading ? null : null,
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadows: isLoading ? null : c.cardShadow,
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(context.l10n.nearbyCheckIn,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: body,
                            fontWeight: FontWeight.w700,
                          )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Checked-in panel ─────────────────────────────────────────────────────────

class _CheckedInPanel extends StatelessWidget {
  const _CheckedInPanel({
    required this.c,
    required this.body,
    required this.label,
    required this.courseName,
    required this.isLookingForGroup,
    required this.incomingRequests,
    required this.onToggle,
    required this.onLeave,
    required this.onAccept,
    required this.onDecline,
  });

  final AppColors c;
  final double body, label;
  final String courseName;
  final bool isLookingForGroup;
  final List<JoinRequest> incomingRequests;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLeave;
  final ValueChanged<JoinRequest> onAccept;
  final ValueChanged<String> onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF8FD44E), size: 18),
              const SizedBox(width: 6),
              Text(context.l10n.nearbyCheckedIn,
                  style: TextStyle(
                    color: const Color(0xFF8FD44E),
                    fontSize: label,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: onLeave,
                child: Text(context.l10n.nearbyLeave,
                    style: TextStyle(
                      color: c.tertiaryText,
                      fontSize: label,
                      decoration: TextDecoration.underline,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(courseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.primaryText,
                fontSize: body,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 12),
          // ── Incoming requests ──────────────────────────────────────────
          if (incomingRequests.isNotEmpty) ...[
            Divider(color: c.fieldBorder, height: 1),
            const SizedBox(height: 10),
            Text(
              'Wants to Join',
              style: TextStyle(
                color: c.secondaryText,
                fontSize: label,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            ...incomingRequests.map(
              (req) => _JoinRequestCard(
                c: c,
                body: body,
                label: label,
                request: req,
                onAccept: onAccept,
                onDecline: onDecline,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Expanded(
                child: Text(context.l10n.nearbyLookingForGroup,
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: body * 0.9,
                    )),
              ),
              Switch.adaptive(
                value: isLookingForGroup,
                onChanged: onToggle,
                activeTrackColor: const Color(0xFF5A9E1F),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Join request card ─────────────────────────────────────────────────────────

class _JoinRequestCard extends StatelessWidget {
  const _JoinRequestCard({
    required this.c,
    required this.body,
    required this.label,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final AppColors c;
  final double body, label;
  final JoinRequest request;
  final ValueChanged<JoinRequest> onAccept;
  final ValueChanged<String> onDecline;

  @override
  Widget build(BuildContext context) {
    final hcpText = request.fromHcp != null
        ? 'HCP ${request.fromHcp!.toStringAsFixed(1)}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: c.fieldBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.fieldBorder),
        ),
      ),
      child: Row(
        children: [
          _NearbyAvatar(
              url: request.fromAvatarUrl,
              name: request.fromDisplayName,
              size: 40,
              c: c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.fromDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.primaryText,
                      fontSize: body,
                      fontWeight: FontWeight.w700,
                    )),
                if (hcpText != null)
                  Text(hcpText,
                      style: TextStyle(
                        color: c.secondaryText,
                        fontSize: label,
                      )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Decline
          GestureDetector(
            onTap: () => onDecline(request.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: ShapeDecoration(
                color: c.fieldBg,
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: c.fieldBorder),
                ),
              ),
              child: Text('Decline',
                  style: TextStyle(
                    color: c.secondaryText,
                    fontSize: label,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
          const SizedBox(width: 6),
          // Accept
          GestureDetector(
            onTap: () => onAccept(request),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: ShapeDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)]),
                shape:
                    SuperellipseShape(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Accept',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: label,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Discovery list ────────────────────────────────────────────────────────────

class _DiscoveryList extends StatelessWidget {
  const _DiscoveryList({
    required this.c,
    required this.body,
    required this.label,
    required this.hPad,
    required this.sh,
    required this.courseId,
    required this.requestSentTo,
    required this.onSendRequest,
    required this.onCancelRequest,
  });

  final AppColors c;
  final double body, label, hPad, sh;
  final String courseId;
  final Set<String> requestSentTo;
  final ValueChanged<UserSession> onSendRequest;
  final ValueChanged<String> onCancelRequest;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserSession>>(
      stream: NearbyPlayersService.nearbyPlayersStream(courseId),
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final players = snap.data ?? [];

        if (loading) {
          return Skeletonizer(
            enabled: true,
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.12),
              itemCount: 3,
              itemBuilder: (context, i) => _PlayerCard(
                c: c,
                body: body,
                label: label,
                session: UserSession(
                  userId: 'dummy',
                  displayName: 'Golfer Name Here',
                  currentCourseId: '',
                  courseName: 'Golf Course Name',
                  isLookingForGroup: true,
                  lat: 0,
                  lng: 0,
                  updatedAt: DateTime.now(),
                  hcp: 12.4,
                ),
                requestSent: false,
                onSendRequest: (_) {},
                onCancelRequest: (_) {},
              ),
            ),
          );
        }

        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 48, color: c.tertiaryText),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Text(
                    context.l10n.nearbyNoOneNearby,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.12),
          itemCount: players.length,
          itemBuilder: (_, i) => _PlayerCard(
            c: c,
            body: body,
            label: label,
            session: players[i],
            requestSent: requestSentTo.contains(players[i].userId),
            onSendRequest: onSendRequest,
            onCancelRequest: onCancelRequest,
          ),
        );
      },
    );
  }
}

// ── Player card ───────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.c,
    required this.body,
    required this.label,
    required this.session,
    required this.requestSent,
    required this.onSendRequest,
    required this.onCancelRequest,
  });

  final AppColors c;
  final double body, label;
  final UserSession session;
  final bool requestSent;
  final ValueChanged<UserSession> onSendRequest;
  final ValueChanged<String> onCancelRequest;

  @override
  Widget build(BuildContext context) {
    final hcpText = session.hcp != null
        ? context.l10n.nearbyHcp(session.hcp!.toStringAsFixed(1))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Row(
        children: [
          _NearbyAvatar(
              url: session.avatarUrl,
              name: session.displayName,
              size: 44,
              c: c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.primaryText,
                      fontSize: body,
                      fontWeight: FontWeight.w700,
                    )),
                if (hcpText != null) ...[
                  const SizedBox(height: 2),
                  Text(hcpText,
                      style: TextStyle(
                        color: c.secondaryText,
                        fontSize: label,
                      )),
                ],
                const SizedBox(height: 2),
                Text(session.courseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.tertiaryText,
                      fontSize: label,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (requestSent) ...[
            // "Sent ✓" label + Cancel button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${context.l10n.nearbyRequestSent} ✓',
                    style: TextStyle(
                      color: const Color(0xFF8FD44E),
                      fontSize: label,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => onCancelRequest(session.userId),
                  child: Text('Cancel',
                      style: TextStyle(
                        color: c.tertiaryText,
                        fontSize: label,
                        decoration: TextDecoration.underline,
                      )),
                ),
              ],
            ),
          ] else
            GestureDetector(
              onTap: () => onSendRequest(session),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)]),
                  shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(14)),
                  shadows: c.cardShadow,
                ),
                child: Text(
                  context.l10n.nearbyRequestJoin,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Avatar for nearby cards ───────────────────────────────────────────────────

class _NearbyAvatar extends StatelessWidget {
  const _NearbyAvatar({
    required this.url,
    required this.name,
    required this.size,
    required this.c,
  });

  final String? url;
  final String name;
  final double size;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(url!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, err, stack) => _initials()),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.accentBg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initial,
            style: TextStyle(
                color: c.accent,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
