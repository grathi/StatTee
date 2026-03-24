import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/places_service.dart';
import '../services/round_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import 'scorecard_screen.dart';

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

  // autocomplete state
  String?  _selectedPlaceId;
  List<GolfCourseSuggestion> _suggestions = [];
  bool     _loadingSuggestions = false;
  Timer?   _debounce;
  Position? _userPosition;
  String?   _locationName;
  double?   _customLat;
  double?   _customLng;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

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
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
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
    _courseNameCtrl.text = s.name;
    _locationCtrl.text   = s.address;
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _teeOff() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // Fetch weather silently in parallel, don't block round creation
      final weatherFuture = _userPosition != null
          ? WeatherService.fetchWeather(_userPosition!.latitude, _userPosition!.longitude)
          : (_customLat != null && _customLng != null)
              ? WeatherService.fetchWeather(_customLat!, _customLng!)
              : Future<WeatherData?>.value(null);

      final weather = await weatherFuture;
      final roundId = await RoundService.startRound(
        courseName:     _courseNameCtrl.text.trim(),
        courseLocation: _locationCtrl.text.trim().isNotEmpty
            ? _locationCtrl.text.trim()
            : (_locationName ?? ''),
        totalHoles:     _holes,
        courseRating:   double.tryParse(_courseRatingCtrl.text.trim()),
        slopeRating:    int.tryParse(_slopeRatingCtrl.text.trim()),
        weather:        weather,
        isPractice:     widget.isPractice,
        tournamentId:   widget.tournamentId,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScorecardScreen(
            roundId:    roundId,
            courseName: _courseNameCtrl.text.trim(),
            totalHoles: _holes,
            weather:    weather,
            onComplete: widget.onComplete,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
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
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(c),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: _hPad),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          children: [
                            SizedBox(height: _sh * 0.02),
                            _buildHeader(c),
                            SizedBox(height: _sh * 0.032),
                            _buildForm(c),
                            SizedBox(height: _sh * 0.036),
                            _buildTeeOffButton(c),
                            SizedBox(height: _sh * 0.04),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppColors c) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _hPad * 0.5, vertical: 4),
      child: Row(
        children: [
          IconButton(
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
          const Spacer(),
          // Location indicator
          if (_userPosition != null || _locationName != null || _customLat != null)
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: c.accent, size: _label * 1.2),
                const SizedBox(width: 4),
                Text(
                  _locationName ?? 'Location found',
                  style: TextStyle(color: c.accent, fontSize: _label),
                ),
              ],
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: c.tertiaryText),
                ),
                const SizedBox(width: 6),
                Text(
                  'Finding location…',
                  style: TextStyle(color: c.tertiaryText, fontSize: _label),
                ),
              ],
            ),
          SizedBox(width: _hPad * 0.5),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    return Column(
      children: [
        Container(
          width: (_sw * 0.18).clamp(60.0, 80.0),
          height: (_sw * 0.18).clamp(60.0, 80.0),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF1A3A08), Color(0xFF8FD44E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset('assets/golfBag.png', fit: BoxFit.contain),
          ),
        ),
        SizedBox(height: _sh * 0.018),
        Text(
          'Start a Round',
          style: TextStyle(fontFamily: 'Nunito',
            color: c.primaryText,
            fontSize: (_sw * 0.072).clamp(24.0, 32.0),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: _sh * 0.006),
        Text(
          'Where are you playing today?',
          style: TextStyle(color: c.secondaryText, fontSize: _body * 0.9),
        ),
      ],
    );
  }

  Widget _buildForm(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
      ),
      padding: EdgeInsets.all((_sw * 0.06).clamp(20.0, 28.0)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(c, 'COURSE DETAILS'),
            SizedBox(height: _sh * 0.014),

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

            SizedBox(height: _sh * 0.028),
            _sectionLabel(c, 'COURSE RATING (OPTIONAL)'),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'For an accurate USGA Handicap Index',
                style: TextStyle(color: c.tertiaryText, fontSize: _label * 0.9),
              ),
            ),
            SizedBox(height: _sh * 0.010),
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

            SizedBox(height: _sh * 0.028),
            _sectionLabel(c, 'NUMBER OF HOLES'),
            SizedBox(height: _sh * 0.014),
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
            decoration: BoxDecoration(
              color: c.sheetBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.cardBorder),
              boxShadow: [
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
                                    decoration: BoxDecoration(
                                      color: c.accentBg,
                                      borderRadius: BorderRadius.circular(8),
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
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF5A9E1F) : c.fieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? const Color(0xFF5A9E1F) : c.fieldBorder,
                  width: selected ? 2 : 1,
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

  Widget _buildTeeOffButton(AppColors c) {
    return SizedBox(
      width: double.infinity,
      height: (_sh * 0.075).clamp(54.0, 66.0),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _teeOff,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A9E1F),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF5A9E1F).withValues(alpha: 0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_golf_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Tee Off!',
                    style: TextStyle(fontFamily: 'Nunito',
                      fontSize: (_sw * 0.048).clamp(16.0, 20.0),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
