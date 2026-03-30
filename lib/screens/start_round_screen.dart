import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../services/places_service.dart';
import '../services/round_service.dart';
import '../services/friends_service.dart';
import '../services/group_round_service.dart';
import '../models/friend_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'scorecard_screen.dart';
import '../services/golf_course_api_service.dart';

class StartRoundScreen extends StatefulWidget {
  final String? initialCourseName;
  final String? initialLocation;
  final bool isPractice;
  final String? tournamentId;
  final void Function(String roundId)? onComplete;
  // Pre-supplied position from the home tab — avoids a second GPS request
  final Position? initialPosition;
  final double? initialCustomLat;
  final double? initialCustomLng;

  const StartRoundScreen({
    super.key,
    this.initialCourseName,
    this.initialLocation,
    this.isPractice = false,
    this.tournamentId,
    this.onComplete,
    this.initialPosition,
    this.initialCustomLat,
    this.initialCustomLng,
  });

  @override
  State<StartRoundScreen> createState() => _StartRoundScreenState();
}

class _StartRoundScreenState extends State<StartRoundScreen>
    with SingleTickerProviderStateMixin {
  final _formKey             = GlobalKey<FormState>();
  final _courseNameCtrl      = TextEditingController();
  final _locationCtrl        = TextEditingController();
  final _courseRatingCtrl    = TextEditingController();
  final _slopeRatingCtrl     = TextEditingController();
  final _courseNameFocus     = FocusNode();
  final _overlayController   = OverlayPortalController();

  int  _holes     = 18;
  bool _isLoading = false;

  // Invite friends
  List<FriendProfile> _acceptedFriends = [];
  final Set<String> _invitedUids = {};
  final _friendSearchCtrl = TextEditingController();
  String _friendQuery = '';
  bool _loadingFriends = false;
  List<GolfApiHole>? _courseHoles;

  // autocomplete state
  String?  _selectedPlaceId;
  double?  _selectedLat;   // lat/lng of the user-selected course from Places API
  double?  _selectedLng;
  List<GolfCourseSuggestion> _suggestions = [];
  bool     _loadingSuggestions = false;
  Timer?   _debounce;
  Position? _userPosition;
  String?   _locationName;
  double?   _customLat;
  double?   _customLng;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  double get _sw  => MediaQuery.of(context).size.width;
  double get _sh  => MediaQuery.of(context).size.height;
  double get _hPad  => (_sw * 0.065).clamp(20.0, 32.0);
  double get _body  => (_sw * 0.036).clamp(13.0, 16.0);
  double get _label => (_sw * 0.030).clamp(11.0, 13.0);
  double get _btnH  => (_sh * 0.068).clamp(48.0, 60.0);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Use position from home tab if available; otherwise fall back to GPS
    if (widget.initialPosition != null) {
      _userPosition = widget.initialPosition;
      _locationName = widget.initialLocation;
    } else if (widget.initialCustomLat != null && widget.initialCustomLng != null) {
      _locationName = widget.initialLocation;
      _customLat    = widget.initialCustomLat;
      _customLng    = widget.initialCustomLng;
    } else if (widget.initialLocation != null && widget.initialCourseName == null) {
      _locationName = widget.initialLocation;
    } else {
      _fetchLocation();
    }

    // Pre-fill location field with the resolved location name
    if (widget.initialCourseName == null && _locationName != null) {
      _locationCtrl.text = _locationName!;
    }

    _courseNameCtrl.addListener(_onCourseNameChanged);

    // Load accepted friends for invite section
    if (!widget.isPractice && widget.tournamentId == null) {
      _loadingFriends = true;
      FriendsService.friendsStream().first.then((all) {
        if (mounted) {
          setState(() {
            _acceptedFriends =
                all.where((f) => f.status == 'accepted').toList();
            _loadingFriends = false;
          });
        }
      });
    }

    // Pre-fill if launched from a nearby course card
    if (widget.initialCourseName != null) {
      _courseNameCtrl.text = widget.initialCourseName!;
      _locationCtrl.text   = widget.initialLocation ?? '';
      _selectedPlaceId     = 'prefilled';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animCtrl.dispose();
    _courseNameCtrl.removeListener(_onCourseNameChanged);
    _courseNameCtrl.dispose();
    _locationCtrl.dispose();
    _courseRatingCtrl.dispose();
    _slopeRatingCtrl.dispose();
    _courseNameFocus.dispose();
    _friendSearchCtrl.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    final pos = await PlacesService.getCurrentLocation();
    if (!mounted || pos == null) {
      if (mounted) setState(() => _userPosition = null);
      return;
    }
    final name = await PlacesService.getLocationName(pos);
    if (mounted) setState(() {
      _userPosition  = pos;
      _locationName  = name;
    });
  }

  // ── Autocomplete logic ────────────────────────────────────────────────────

  void _onCourseNameChanged() {
    // If already selected, ignore the change triggered by setText
    if (_selectedPlaceId != null) return;

    _debounce?.cancel();
    final text = _courseNameCtrl.text.trim();

    if (text.length < 2) {
      setState(() => _suggestions = []);
      if (_overlayController.isShowing) _overlayController.hide();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _loadingSuggestions = true);
      if (!_overlayController.isShowing) _overlayController.show();

      final results = await PlacesService.autocomplete(
        input: text,
        location: _userPosition,
        lat: _customLat,
        lng: _customLng,
        locationName: _locationName,
      );

      if (!mounted) return;
      setState(() {
        _suggestions        = results;
        _loadingSuggestions = false;
      });
    });
  }

  Future<void> _selectSuggestion(GolfCourseSuggestion s) async {
    // Hide overlay and clear suggestions first
    if (_overlayController.isShowing) _overlayController.hide();
    // Set selectedPlaceId BEFORE updating text so listener ignores the change
    _selectedPlaceId = s.placeId;
    _selectedLat = null;
    _selectedLng = null;
    _courseNameCtrl.text = s.name;
    _locationCtrl.text   = s.address;
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();

    // Fetch course coordinates in the background for accurate weather during scoring
    if (s.placeId.isNotEmpty && s.placeId != 'prefilled') {
      PlacesService.getPlaceDetail(s.placeId).then((detail) {
        if (mounted && detail?.lat != null && detail?.lng != null) {
          setState(() {
            _selectedLat = detail!.lat;
            _selectedLng = detail.lng;
          });
        }
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _teeOff() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final courseName     = _courseNameCtrl.text.trim();
      final courseLocation = _locationCtrl.text.trim().isNotEmpty
          ? _locationCtrl.text.trim()
          : (_locationName ?? '');
      final courseRating   = double.tryParse(_courseRatingCtrl.text.trim());
      final slopeRating    = int.tryParse(_slopeRatingCtrl.text.trim());

      // Fetch hole data from GolfCourseAPI in parallel with round creation
      final results = await Future.wait([
        RoundService.startRound(
          courseName:     courseName,
          courseLocation: courseLocation,
          totalHoles:     _holes,
          courseRating:   courseRating,
          slopeRating:    slopeRating,
          weather:        null,
          isPractice:     widget.isPractice,
          tournamentId:   widget.tournamentId,
        ),
        GolfCourseApiService.findBestMatch(
          courseName,
          address: courseLocation.isNotEmpty ? courseLocation : null,
        ),
      ]);

      final roundId    = results[0] as String;
      final courseDetail = results[1] as GolfApiCourseDetail?;

      // Pick the tee with the closest hole count to _holes
      List<GolfApiHole>? holes;
      if (courseDetail != null && courseDetail.hasTeeData) {
        final tees = courseDetail.availableTees;
        GolfApiTee? best;
        int bestDiff = 999;
        for (final t in tees) {
          final diff = (t.effectiveHoles.length - _holes).abs();
          if (diff < bestDiff) { bestDiff = diff; best = t; }
        }
        if (best != null) holes = best.effectiveHoles;
      }

      // Create group session if friends were invited
      String? sessionId;
      final invitees = _acceptedFriends
          .where((f) => _invitedUids.contains(f.uid))
          .toList();
      if (invitees.isNotEmpty) {
        sessionId = await GroupRoundService.createSession(
          courseName:     courseName,
          courseLocation: courseLocation,
          totalHoles:     _holes,
          courseRating:   courseRating,
          slopeRating:    slopeRating,
          invitees:       invitees,
        );
        await GroupRoundService.joinSession(sessionId, roundId);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScorecardScreen(
            roundId:        roundId,
            courseName:     courseName,
            totalHoles:     _holes,
            lat:            _selectedLat ?? _userPosition?.latitude ?? _customLat,
            lng:            _selectedLng ?? _userPosition?.longitude ?? _customLng,
            onComplete:     widget.onComplete,
            sessionId:      sessionId,
            preloadedHoles: holes,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c.bgGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Content ───────────────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: _hPad),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      SizedBox(height: _sh * 0.068),
                      _buildHeader(c),
                      SizedBox(height: _sh * 0.020),
                      _buildForm(c),
                      if (_acceptedFriends.isNotEmpty && !widget.isPractice &&
                          widget.tournamentId == null) ...[
                        SizedBox(height: _sh * 0.018),
                        _buildInviteSection(c),
                      ],
                      SizedBox(height: _sh * 0.024),
                      _buildTeeOffButton(c),
                      SizedBox(height: _sh * 0.028),
                    ],
                  ),
                ),
              ),
            ),
            // ── Floating back arrow ───────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: _hPad * 0.5, top: 4),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    width: (_sw * 0.095).clamp(34.0, 44.0),
                    height: (_sw * 0.095).clamp(34.0, 44.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.iconContainerBg,
                      border: Border.all(color: c.iconContainerBorder),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: c.iconColor, size: _body),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    final cardH = (_sh * 0.195).clamp(150.0, 190.0);
    const overflowTop = 55.0;
    return SizedBox(
      height: cardH + overflowTop,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Card ──────────────────────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: cardH,
            child: Container(
              decoration: ShapeDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E6B10), Color(0xFF4E9E20), Color(0xFF7BC344)],
                  stops: [0.0, 0.55, 1.0],
                ),
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(48),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF5A9E1F).withValues(alpha: 0.38),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: (_sw * 0.058).clamp(18.0, 26.0),
                top: (_sw * 0.038).clamp(10.0, 16.0),
                bottom: (_sw * 0.038).clamp(10.0, 16.0),
                right: (_sw * 0.42).clamp(130.0, 170.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: ShapeDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Text('📍  Pick your course',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: _label * 0.9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: _sh * 0.007),
                  Text('Where are\nyou playing?',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: (_sw * 0.065).clamp(22.0, 28.0),
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: _sh * 0.005),
                  Text('Search for a nearby golf course',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: _body * 0.82,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Golf bag — anchored to card bottom, overflows above card ─
          Positioned(
            right: 0,
            bottom: 0,
            top: -40,  // fills full SizedBox = cardH + overflowTop
            width: (_sw * 0.46).clamp(145.0, 185.0),
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerRight,
                child: Image.asset(
                  'assets/golfBag.png',
                  height: double.infinity,
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppColors c) {
    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((_sw * 0.048).clamp(16.0, 22.0)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(c, 'COURSE DETAILS'),
            SizedBox(height: _sh * 0.010),

            // ── Course name with autocomplete ─────────────────────────────
            OverlayPortal(
              controller: _overlayController,
              overlayChildBuilder: (_) => _buildSuggestionsOverlay(c),
              child: CompositedTransformTarget(
                link: _layerLink,
                child: TextFormField(
                  controller: _courseNameCtrl,
                  focusNode: _courseNameFocus,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: c.fieldText, fontSize: _body),
                  onTap: () {
                    // If user taps to edit again after selection, reset
                    if (_selectedPlaceId != null) {
                      setState(() {
                        _selectedPlaceId = null;
                        _locationCtrl.clear();
                      });
                    }
                  },
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter course name'
                      : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: 'Course Name',
                    labelStyle:
                        TextStyle(color: c.fieldLabel, fontSize: _body * 0.9),
                    prefixIcon: Icon(Icons.golf_course_rounded,
                        color: c.fieldIcon, size: _body * 1.3),
                    suffixIcon: _loadingSuggestions
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: c.accent),
                            ),
                          )
                        : (_courseNameCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: c.tertiaryText, size: 18),
                                onPressed: () {
                                  _courseNameCtrl.clear();
                                  _locationCtrl.clear();
                                  _selectedPlaceId = null;
                                  _selectedLat = null;
                                  _selectedLng = null;
                                  _overlayController.hide();
                                  setState(() => _suggestions = []);
                                },
                              )
                            : null),
                    filled: true,
                    fillColor: c.fieldBg,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: c.fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: c.accent, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE53935)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE53935), width: 1.5),
                    ),
                    errorStyle:
                        const TextStyle(color: Color(0xFFE53935), fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: (_btnH * 0.28).clamp(12.0, 18.0)),
                  ),
                ),
              ),
            ),

            SizedBox(height: _sh * 0.018),
            _sectionLabel(c, 'COURSE RATING (OPTIONAL)'),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                'For an accurate USGA Handicap Index',
                style: TextStyle(color: c.tertiaryText, fontSize: _label * 0.9),
              ),
            ),
            SizedBox(height: _sh * 0.008),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _courseRatingCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: c.fieldText, fontSize: _body),
                    decoration: InputDecoration(
                      labelText: 'Course Rating',
                      hintText: 'e.g. 72.5',
                      labelStyle: TextStyle(color: c.fieldLabel, fontSize: _body * 0.9),
                      prefixIcon: Icon(Icons.score_rounded, color: c.fieldIcon, size: _body * 1.3),
                      filled: true,
                      fillColor: c.fieldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.fieldBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.accent),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: (_btnH * 0.28).clamp(12.0, 18.0)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final val = double.tryParse(v.trim());
                      if (val == null || val < 60 || val > 80) return '60–80';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _slopeRatingCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: c.fieldText, fontSize: _body),
                    decoration: InputDecoration(
                      labelText: 'Slope Rating',
                      hintText: 'e.g. 113',
                      labelStyle: TextStyle(color: c.fieldLabel, fontSize: _body * 0.9),
                      prefixIcon: Icon(Icons.trending_up_rounded, color: c.fieldIcon, size: _body * 1.3),
                      filled: true,
                      fillColor: c.fieldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.fieldBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.accent),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: (_btnH * 0.28).clamp(12.0, 18.0)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final val = int.tryParse(v.trim());
                      if (val == null || val < 55 || val > 155) return '55–155';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: _sh * 0.018),
            _sectionLabel(c, 'NUMBER OF HOLES'),
            SizedBox(height: _sh * 0.010),
            _buildHolesSelector(c),
          ],
        ),
      ),
    );
  }

  // ── Suggestions overlay ───────────────────────────────────────────────────

  final LayerLink _layerLink = LayerLink();

  Widget _buildSuggestionsOverlay(AppColors c) {
    return Positioned(
      width: _sw - (_hPad * 2) - ((_sw * 0.06).clamp(20.0, 28.0) * 2),
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, (_sh * 0.068).clamp(48.0, 60.0) + 4),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: (_sh * 0.35).clamp(180.0, 280.0),
            ),
            decoration: ShapeDecoration(
              color: c.sheetBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(32),
                side: BorderSide(color: c.cardBorder),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _loadingSuggestions && _suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.accent),
                    ),
                  )
                : _suggestions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No golf courses found nearby',
                          style: TextStyle(
                              color: c.secondaryText, fontSize: _label),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: c.divider),
                        itemBuilder: (_, i) {
                          final s = _suggestions[i];
                          return InkWell(
                            onTap: () => _selectSuggestion(s),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: ShapeDecoration(
                                      color: c.accentBg,
                                      shape: SuperellipseShape(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Icon(Icons.golf_course_rounded,
                                        color: c.accent, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: TextStyle(fontFamily: 'Nunito',
                                            color: c.primaryText,
                                            fontSize: _body,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (s.address.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            s.address,
                                            style: TextStyle(
                                                color: c.tertiaryText,
                                                fontSize: _label),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.north_west_rounded,
                                      color: c.tertiaryText, size: 14),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(AppColors c, String text) => Text(
        text,
        style: TextStyle(
          color: c.accent,
          fontSize: _label,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  Widget _buildHolesSelector(AppColors c) {
    return Row(
      children: [9, 18].map((h) {
        final selected = _holes == h;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _holes = h),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: h == 9 ? 8 : 0),
              height: (_sh * 0.068).clamp(52.0, 64.0),
              decoration: ShapeDecoration(
                color: selected ? const Color(0xFF5A9E1F) : c.fieldBg,
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: selected ? const Color(0xFF5A9E1F) : c.fieldBorder,
                    width: selected ? 2 : 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$h',
                    style: TextStyle(fontFamily: 'Nunito',
                      color: selected ? Colors.white : c.primaryText,
                      fontSize: (_sw * 0.055).clamp(18.0, 24.0),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Holes',
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.8)
                          : c.secondaryText,
                      fontSize: _label,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInviteSection(AppColors c) {
    // Selected friends always appear first, then alphabetical
    final filtered = _acceptedFriends
        .where((f) =>
            _friendQuery.isEmpty ||
            f.displayName.toLowerCase().contains(_friendQuery.toLowerCase()))
        .toList()
      ..sort((a, b) {
        final asel = _invitedUids.contains(a.uid) ? 0 : 1;
        final bsel = _invitedUids.contains(b.uid) ? 0 : 1;
        if (asel != bsel) return asel - bsel;
        return a.displayName.compareTo(b.displayName);
      });

    final atMax = _invitedUids.length >= 3;
    final pad = (_sw * 0.048).clamp(16.0, 22.0);

    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(c, 'INVITE FRIENDS (MAX 3)'),
          SizedBox(height: _sh * 0.010),
          // ── Search field ────────────────────────────────────────────────
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: c.fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.fieldBorder),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search_rounded, size: 16, color: c.tertiaryText),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _friendSearchCtrl,
                    style: TextStyle(color: c.fieldText, fontSize: _label),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search friends…',
                      hintStyle: TextStyle(color: c.tertiaryText, fontSize: _label),
                    ),
                    onChanged: (v) => setState(() => _friendQuery = v),
                  ),
                ),
                if (_friendQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _friendSearchCtrl.clear();
                      setState(() => _friendQuery = '');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.close_rounded, size: 14, color: c.tertiaryText),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: _sh * 0.012),
          // ── Avatar scroll (Skeletonizer handles loading state) ───────────
          if (!_loadingFriends && filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _friendQuery.isEmpty ? 'No friends yet.' : 'No matches.',
                style: TextStyle(color: c.tertiaryText, fontSize: _label),
              ),
            )
          else
            Skeletonizer(
              enabled: _loadingFriends,
              child: SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: _loadingFriends
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: _loadingFriends ? 5 : filtered.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) {
                  final f = _loadingFriends
                      ? FriendProfile(
                          uid: 'dummy_$i',
                          displayName: 'Golfer Name',
                          email: '',
                          status: 'accepted',
                          addedAt: DateTime.now(),
                        )
                      : filtered[i];
                  final sel = _invitedUids.contains(f.uid);
                  final disabled = !sel && atMax;
                  return GestureDetector(
                    onTap: () {
                      if (disabled) return;
                      setState(() {
                        if (sel) {
                          _invitedUids.remove(f.uid);
                        } else {
                          _invitedUids.add(f.uid);
                        }
                      });
                    },
                    child: SizedBox(
                      width: 58,
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Avatar circle
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: sel
                                        ? const Color(0xFF5A9E1F)
                                        : (disabled
                                            ? c.cardBorder.withValues(alpha: 0.3)
                                            : c.cardBorder),
                                    width: sel ? 2.5 : 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: f.avatarUrl != null
                                      ? Image.network(
                                          f.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _avatarFallback(c, f, disabled),
                                        )
                                      : _avatarFallback(c, f, disabled),
                                ),
                              ),
                              // Green check badge
                              if (sel)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF5A9E1F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            f.displayName.split(' ').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: sel
                                  ? c.primaryText
                                  : (disabled ? c.tertiaryText.withValues(alpha: 0.4) : c.secondaryText),
                              fontSize: _label * 0.9,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ),  // Skeletonizer
          // ── Selected count pill ──────────────────────────────────────────
          if (_invitedUids.isNotEmpty) ...[
            SizedBox(height: _sh * 0.010),
            Text(
              '${_invitedUids.length} friend${_invitedUids.length > 1 ? 's' : ''} will be invited',
              style: TextStyle(
                  color: c.accent, fontSize: _label, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarFallback(AppColors c, FriendProfile f, bool disabled) {
    return Container(
      color: disabled ? c.fieldBg : c.fieldBg,
      alignment: Alignment.center,
      child: Text(
        f.displayName.isNotEmpty ? f.displayName[0].toUpperCase() : '?',
        style: TextStyle(
          color: disabled ? c.tertiaryText.withValues(alpha: 0.4) : c.secondaryText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTeeOffButton(AppColors c) {
    return GestureDetector(
      onTap: _isLoading ? null : _teeOff,
      child: Opacity(
        opacity: _isLoading ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          height: (_sh * 0.075).clamp(54.0, 66.0),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7BC344), Color(0xFF5A9E1F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(48),
            ),
            shadows: [
              BoxShadow(
                color: const Color(0xFF5A9E1F).withValues(alpha: 0.40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_golf_rounded, size: 22, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Tee Off!',
                      style: TextStyle(fontFamily: 'Nunito',
                        fontSize: (_sw * 0.048).clamp(16.0, 20.0),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
