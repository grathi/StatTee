import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/hole_score.dart';
import '../models/round.dart';
import '../models/tournament.dart';
import '../services/places_service.dart';
import '../services/round_service.dart';
import '../services/stats_service.dart';
import '../services/tournament_service.dart';
import '../theme/app_theme.dart';
import 'start_round_screen.dart';
import 'scorecard_screen.dart';
import 'rounds_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'package:superellipse_shape/superellipse_shape.dart';

// ---------------------------------------------------------------------------
// Shell — owns the bottom nav and tab switching
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final _homeTabKey = GlobalKey<_HomeTabState>();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: c.scaffoldBg,
      body: Stack(
        children: [
          IndexedStack(
            index: _navIndex,
            children: [
              _HomeTab(key: _homeTabKey, onViewAllRounds: () => setState(() => _navIndex = 1)),
              const RoundsScreen(),
              const StatsScreen(),
              const ProfileScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -4,
            child: IgnorePointer(
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                  stops: const [0.0, 0.35],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/bg_image.png',
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(c),
    );
  }

  void _showStartSheet(
      BuildContext context, AppColors c, double sw, double sh) {
    final tab = _homeTabKey.currentState;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StartModeSheet(
        c: c, sw: sw, sh: sh,
        userPosition: tab?._userPosition,
        customLat: tab?._customLat,
        customLng: tab?._customLng,
        locationName: tab?._locationName,
      ),
    );
  }

  Widget _buildBottomNav(AppColors c) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final pillH   = (sh * 0.082).clamp(62.0, 72.0);
    final hPad    = (sw * 0.042).clamp(14.0, 22.0);
    final pillW   = sw - hPad * 2;
    final iconSz  = (sw * 0.054).clamp(20.0, 24.0);
    final lblSz   = (sw * 0.030).clamp(11.0, 13.0);
    final playDia = (sw * 0.100).clamp(36.0, 44.0);

    const navItems = [
      (Icons.home_rounded,        Icons.home_outlined,          'Home',    0),
      (Icons.golf_course_rounded, Icons.golf_course_outlined,   'Rounds',  1),
      (Icons.bar_chart_rounded,   Icons.bar_chart_outlined,     'Stats',   2),
      (Icons.person_rounded,      Icons.person_outline_rounded, 'Profile', 3),
    ];

    // iOS 18-style expanding chip: active = icon + label in tinted capsule
    Widget tabChip(IconData fillIcon, IconData lineIcon, String label, int idx) {
      final active = _navIndex == idx;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _navIndex = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: active ? 14.0 : 11.0,
            vertical: 9.0,
          ),
          decoration: BoxDecoration(
            color: active
                ? c.accent.withValues(alpha: c.isDark ? 0.18 : 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? fillIcon : lineIcon,
                color: active ? c.accent : c.navInactive,
                size: iconSz,
              ),
              // Label slides in via AnimatedSize — no margin so no assertion risk
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: active
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              color: c.accent,
                              fontSize: lblSz,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    // Shadow lives on outer Container; blur lives inside ClipRRect
    return SizedBox(
      height: pillH + bottomPad + 8,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: pillW,
          height: pillH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(pillH / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(pillH / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: c.navBg,
                  borderRadius: BorderRadius.circular(pillH / 2),
                  border: Border.all(
                    color: c.navBorder.withValues(alpha: 0.50),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    tabChip(navItems[0].$1, navItems[0].$2, navItems[0].$3, navItems[0].$4),
                    const Spacer(),
                    tabChip(navItems[1].$1, navItems[1].$2, navItems[1].$3, navItems[1].$4),
                    const Spacer(),
                    // Centre play button — always a gradient circle
                    GestureDetector(
                      onTap: () => _showStartSheet(context, c, sw, sh),
                      child: Container(
                        width: playDia,
                        height: playDia,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7BC344), Color(0xFF3D7A14)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3D7A14).withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.sports_golf_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    tabChip(navItems[2].$1, navItems[2].$2, navItems[2].$3, navItems[2].$4),
                    const Spacer(),
                    tabChip(navItems[3].$1, navItems[3].$2, navItems[3].$3, navItems[3].$4),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HomeTab — tab 0 content
// ---------------------------------------------------------------------------
class _HomeTab extends StatefulWidget {
  final VoidCallback? onViewAllRounds;
  const _HomeTab({super.key, this.onViewAllRounds});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  Position? _userPosition;
  String?   _locationName;
  double?   _customLat;
  double?   _customLng;
  List<GolfCourseDetail> _nearbyCourses = [];
  bool _loadingNearby = false;
  int  _loadGeneration = 0; // incremented each time a new load starts

  double get _sw => MediaQuery.of(context).size.width;
  double get _sh => MediaQuery.of(context).size.height;
  double get _hPad => (_sw * 0.055).clamp(18.0, 28.0);
  double get _bodySize => (_sw * 0.036).clamp(13.0, 16.0);
  double get _labelSize => (_sw * 0.030).clamp(11.0, 13.0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadNearbyCourses();
  }

  Future<void> _loadNearbyCourses() async {
    final gen = ++_loadGeneration;
    setState(() => _loadingNearby = true);

    // Custom location path — no GPS needed
    if (_customLat != null && _customLng != null) {
      final courses = await PlacesService.nearbyGolfCourses(
        null, lat: _customLat, lng: _customLng,
      );
      if (!mounted || gen != _loadGeneration) return;
      setState(() { _nearbyCourses = courses; _loadingNearby = false; });
      return;
    }

    // GPS path
    final pos = await PlacesService.getCurrentLocation();
    if (!mounted || gen != _loadGeneration) return;
    if (pos == null) {
      setState(() => _loadingNearby = false);
      return;
    }
    final name    = await PlacesService.getLocationName(pos);
    final courses = await PlacesService.nearbyGolfCourses(pos);
    if (!mounted || gen != _loadGeneration) return;
    setState(() {
      _userPosition  = pos;
      _locationName  = name;
      _nearbyCourses = courses;
      _loadingNearby = false;
    });
  }

  Future<void> _showLocationPicker() async {
    final c = AppColors.of(context);
    final sw = _sw; final sh = _sh;
    final searchCtrl = TextEditingController();
    bool searching = false;
    String? searchError;
    List<({String description, String mainText, String secondaryText})> suggestions = [];

    BuildContext? sheetCtxRef;

    Future<void> doSearch(String q, StateSetter setSheet) async {
      if (q.isEmpty) return;
      setSheet(() { searching = true; searchError = null; });
      final result = await PlacesService.searchGolfCoursesByCity(q);
      if (!mounted) return;
      if (result == null) {
        setSheet(() { searching = false; searchError = 'Location not found. Try a different city name.'; });
        return;
      }
      ++_loadGeneration;
      setState(() {
        _locationName  = result.label;
        _nearbyCourses = result.courses;
        _userPosition  = null;
        _customLat     = result.lat;
        _customLng     = result.lng;
        _loadingNearby = false;
      });
      if (mounted && sheetCtxRef != null) Navigator.pop(sheetCtxRef!);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          sheetCtxRef = sheetCtx;
          return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: c.sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: c.cardBorder)),
            ),
            padding: EdgeInsets.fromLTRB(
                (sw * 0.065).clamp(20.0, 32.0), 20,
                (sw * 0.065).clamp(20.0, 32.0),
                (sh * 0.04).clamp(24.0, 40.0)),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                SizedBox(height: sh * 0.024),
                // Header
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.accentBg, border: Border.all(color: c.accentBorder)),
                    child: Icon(Icons.location_on_rounded, color: c.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Change Location', style: TextStyle(fontFamily: 'Nunito', color: c.primaryText, fontSize: (_sw * 0.048).clamp(16.0, 20.0), fontWeight: FontWeight.w700)),
                    Text('Search a city or area', style: TextStyle(color: c.secondaryText, fontSize: _bodySize * 0.85)),
                  ]),
                ]),
                SizedBox(height: sh * 0.024),
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: c.fieldBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.fieldBorder),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(color: c.fieldText, fontSize: _bodySize),
                    decoration: InputDecoration(
                      hintText: 'e.g. Dubai, London, New York…',
                      hintStyle: TextStyle(color: c.tertiaryText, fontSize: _bodySize),
                      prefixIcon: Icon(Icons.search_rounded, color: c.fieldIcon, size: _bodySize * 1.3),
                      suffixIcon: searching
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (v) async {
                      if (searchError != null) setSheet(() => searchError = null);
                      if (v.trim().length < 2) {
                        setSheet(() => suggestions = []);
                        return;
                      }
                      final results = await PlacesService.getCitySuggestions(v);
                      setSheet(() => suggestions = results);
                    },
                    onSubmitted: (v) => doSearch(v.trim(), setSheet),
                  ),
                ),
                // Suggestions dropdown
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.cardBorder),
                      boxShadow: c.cardShadow,
                    ),
                    child: Column(
                      children: suggestions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        final isLast = i == suggestions.length - 1;
                        return GestureDetector(
                          onTap: () {
                            searchCtrl.text = s.description;
                            setSheet(() => suggestions = []);
                            doSearch(s.description, setSheet);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              border: isLast ? null : Border(bottom: BorderSide(color: c.divider)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_rounded, color: c.accent, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: s.mainText,
                                          style: TextStyle(color: c.primaryText, fontSize: _bodySize, fontWeight: FontWeight.w600),
                                        ),
                                        if (s.secondaryText.isNotEmpty)
                                          TextSpan(
                                            text: '  ${s.secondaryText}',
                                            style: TextStyle(color: c.secondaryText, fontSize: _bodySize * 0.85),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (searchError != null) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 15),
                    const SizedBox(width: 6),
                    Text(searchError!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
                  ]),
                ],
                SizedBox(height: sh * 0.018),
                // Use current location button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _customLat = null;
                      _customLng = null;
                      _locationName = null;
                      _userPosition = null;
                      _nearbyCourses = [];
                    });
                    Navigator.pop(sheetCtxRef!);
                    _loadNearbyCourses();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.accentBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.accentBorder),
                    ),
                    child: Row(children: [
                      Icon(Icons.my_location_rounded, color: c.accent, size: 18),
                      const SizedBox(width: 10),
                      Text('Use my current location', style: TextStyle(color: c.accent, fontSize: _bodySize, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                SizedBox(height: sh * 0.016),
                // Search button
                SizedBox(
                  height: (_sh * 0.065).clamp(48.0, 58.0),
                  child: ElevatedButton(
                    onPressed: searching ? null : () => doSearch(searchCtrl.text.trim(), setSheet),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9E1F),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF5A9E1F).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: searching
                        ? SizedBox(width: 18, height: 18, child: const CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : Text('Search Location', style: TextStyle(fontSize: _bodySize, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            ),  // SingleChildScrollView
          ),       // Container
          );       // Padding / return
        },  // StatefulBuilder
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  String get _firstName {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? 'Golfer';
    return name.split(' ').first;
  }

  String get _initials {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return '1 week ago';
    if (diff.inDays < 21) return '2 weeks ago';
    if (diff.inDays < 30) return '3 weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  Color _diffColor(int diff) {
    if (diff < 0) return const Color(0xFF8FD44E);
    if (diff == 0) return const Color(0xFFFFB74D);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return StreamBuilder<Round?>(
      stream: RoundService.activeRoundStream(),
      builder: (context, activeSnap) {
        final activeRound = activeSnap.data;
        return StreamBuilder<List<Round>>(
          stream: RoundService.recentRoundsStream(limit: 10),
          builder: (context, recentSnap) {
            final recentRounds = recentSnap.data ?? [];
            return StreamBuilder<List<Round>>(
              stream: RoundService.allCompletedRoundsStream(),
              builder: (context, allSnap) {
                final stats = StatsService.calculate(allSnap.data ?? []);
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: c.bgGradient,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          _buildHeader(c),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: _sh * 0.022),
                                  _buildStartRoundCTA(activeRound),
                                  SizedBox(height: _sh * 0.024),
                                  _buildRecentRounds(activeRound, recentRounds),
                                  SizedBox(height: _sh * 0.024),
                                  _buildPerformanceSummary(stats),
                                  SizedBox(height: _sh * 0.024),
                                  _buildQuickStats(stats),
                                  SizedBox(height: _sh * 0.024),
                                  _buildNearbyCourses(),
                                  SizedBox(height: _sh * 0.14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(AppColors c) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_hPad, _sh * 0.018, _hPad, _sh * 0.012),
      child: Row(
        children: [
          Container(
            width: (_sw * 0.115).clamp(40.0, 52.0),
            height: (_sw * 0.115).clamp(40.0, 52.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: const Color(0xFF8FD44E).withValues(alpha: 0.5),
                  width: 2),
            ),
            child: Center(
              child: Text(
                _initials,
                style: TextStyle(fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: (_sw * 0.040).clamp(14.0, 18.0),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: _sw * 0.030),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting,',
                  style: TextStyle(
                    color: c.secondaryText,
                    fontSize: _labelSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _firstName,
                  style: TextStyle(fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: (_sw * 0.050).clamp(17.0, 22.0),
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Builder(builder: (_) {
                  final now = DateTime.now();
                  const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
                  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                  final dateLabel = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
                  return Text(
                    dateLabel,
                    style: TextStyle(color: c.tertiaryText, fontSize: _labelSize * 0.95),
                  );
                }),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: (_sw * 0.110).clamp(38.0, 48.0),
                  height: (_sw * 0.110).clamp(38.0, 48.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.iconContainerBg,
                    border:
                        Border.all(color: c.iconContainerBorder, width: 1),
                  ),
                  child: Icon(Icons.notifications_none_rounded,
                      color: c.iconColor,
                      size: (_sw * 0.056).clamp(20.0, 24.0)),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Start Round / Continue Round CTA ─────────────────────────────────────
  Widget _buildStartRoundCTA(Round? activeRound) {
    final hasActive = activeRound != null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _hPad),
      child: GestureDetector(
        onTap: () {
          if (hasActive) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ScorecardScreen(
                roundId: activeRound.id!,
                courseName: activeRound.courseName,
                totalHoles: activeRound.totalHoles,
              ),
            ));
          } else {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => StartRoundScreen(
                initialPosition: _userPosition,
                initialCustomLat: _customLat,
                initialCustomLng: _customLng,
                initialLocation: _locationName,
              ),
            ));
          }
        },
        child: Container(
          width: double.infinity,
          height: (_sh * 0.195).clamp(150.0, 200.0),
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3A08), Color(0xFF3D6E14), Color(0xFF5A9E1F)],
              stops: [0.0, 0.55, 1.0],
            ),
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(48),
            ),
            shadows: [
              BoxShadow(
                color: const Color(0xFF5A9E1F).withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipSuperellipse(
                  cornerRadius: 40,
                  child: CustomPaint(painter: _CourseSilhouettePainter()),
                ),
              ),
              Positioned.fill(
                child: ClipSuperellipse(
                  cornerRadius: 40,
                  child: Image.asset(
                    'assets/hero.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipSuperellipse(
                  cornerRadius: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.60],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all((_sw * 0.058).clamp(18.0, 26.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hasActive ? '⛳  Round in progress' : '⛳  Ready to play?',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: _labelSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: _sh * 0.012),
                    Text(
                      hasActive ? 'Continue Round' : 'Start Round',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontSize: (_sw * 0.075).clamp(26.0, 34.0),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: _sh * 0.006),
                    if (hasActive)
                      Text(
                        '${activeRound.courseName}  •  ${activeRound.holesPlayed}/${activeRound.totalHoles} holes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: _bodySize * 0.875,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Row(
                        children: [
                          Text(
                            'Tap to tee off',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: _bodySize * 0.875,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: _bodySize),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recent Rounds ─────────────────────────────────────────────────────────
  Widget _buildRecentRounds(Round? activeRound, List<Round> recentRounds) {
    final c = AppColors.of(context);
    final allCards = <_RoundCardData>[];
    if (activeRound != null) {
      allCards.add(_RoundCardData.fromRound(activeRound,
          isActive: true, timeAgo: 'In Progress'));
    }
    for (final r in recentRounds) {
      allCards.add(_RoundCardData.fromRound(r,
          isActive: false, timeAgo: _timeAgo(r.startedAt)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Recent Rounds'),
              GestureDetector(
                onTap: widget.onViewAllRounds,
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: _labelSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _sh * 0.016),
        if (allCards.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _hPad),
            child: _buildEmptyRoundsCard(c),
          )
        else
          SizedBox(
            height: (_sh * 0.155).clamp(120.0, 145.0),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: _hPad),
              itemCount: allCards.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () {
                  if (allCards[i].isActive && activeRound != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ScorecardScreen(
                        roundId: activeRound.id!,
                        courseName: activeRound.courseName,
                        totalHoles: activeRound.totalHoles,
                      ),
                    ));
                  }
                },
                child: _buildRoundCard(allCards[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyRoundsCard(AppColors c) {
    return Container(
      width: double.infinity,
      height: (_sh * 0.155).clamp(120.0, 145.0),
      decoration: ShapeDecoration(
        gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.golf_course_rounded,
                color: c.tertiaryText,
                size: (_sw * 0.08).clamp(28.0, 36.0)),
            const SizedBox(height: 8),
            Text(
              'No rounds yet — start your first!',
              style: TextStyle(color: c.secondaryText, fontSize: _labelSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundCard(_RoundCardData round) {
    final c = AppColors.of(context);
    final diffColor = _diffColor(round.diff);
    final cardW = (_sw * 0.52).clamp(175.0, 220.0);
    return Container(
      width: cardW,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          colors: round.isActive
              ? [c.cardBg.withValues(alpha: c.isDark ? 0.11 : 1.0), c.cardBg.withValues(alpha: c.isDark ? 0.11 : 1.0)]
              : c.cardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(
            color: round.isActive ? c.accentBorder : c.cardBorder,
          ),
        ),
        shadows: round.isActive ? [] : c.cardShadow,
      ),
      padding: EdgeInsets.all((_sw * 0.042).clamp(14.0, 18.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  round.course,
                  style: TextStyle(fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: _bodySize,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (round.isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.accentBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.accentBorder),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: c.accent,
                      fontSize: _labelSize * 0.9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: c.tertiaryText, size: _labelSize),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  round.location.isNotEmpty ? round.location : 'No location',
                  style: TextStyle(color: c.tertiaryText, fontSize: _labelSize),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (round.scores.isNotEmpty) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: round.scores.map((h) {
                  Color hc(int d) {
                    if (d <= -2) return const Color(0xFFFFD700);
                    if (d == -1) return const Color(0xFF8FD44E);
                    if (d == 0)  return const Color(0xFFFFB74D);
                    if (d == 1)  return const Color(0xFFFFB74D);
                    return const Color(0xFFFF6B6B);
                  }
                  final diff = h.score - h.par;
                  return Expanded(child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: hc(diff),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ));
                }).toList(),
              ),
            ),
            const SizedBox(height: 5),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    round.isActive
                        ? '${round.holesPlayed}/${round.totalHoles}'
                        : '${round.score}',
                    style: TextStyle(fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: (_sw * 0.058).clamp(20.0, 26.0),
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    round.isActive ? 'Holes' : 'Score',
                    style:
                        TextStyle(color: c.tertiaryText, fontSize: _labelSize),
                  ),
                ],
              ),
              if (!round.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    round.diffLabel,
                    style: TextStyle(fontFamily: 'Nunito',
                      color: diffColor,
                      fontSize: _bodySize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${round.totalHoles}H',
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: _bodySize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    round.timeAgo,
                    style:
                        TextStyle(color: c.tertiaryText, fontSize: _labelSize),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Performance Summary ───────────────────────────────────────────────────
  Widget _buildPerformanceSummary(AppStats stats) {
    final c = AppColors.of(context);
    final hasData = stats.totalRounds > 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Performance'),
          SizedBox(height: _sh * 0.016),
          Container(
            decoration: ShapeDecoration(
              gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(48),
                side: BorderSide(color: c.cardBorder),
              ),
              shadows: c.cardShadow,
            ),
            padding: EdgeInsets.all((_sw * 0.055).clamp(18.0, 24.0)),
            child: hasData
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Handicap Index',
                                  style: TextStyle(
                                    color: c.secondaryText,
                                    fontSize: _labelSize,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  stats.handicapLabel,
                                  style: TextStyle(fontFamily: 'Nunito',
                                    color: c.primaryText,
                                    fontSize: (_sw * 0.115).clamp(38.0, 52.0),
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildHandicapRing(c, stats.handicapIndex),
                        ],
                      ),
                      SizedBox(height: _sh * 0.022),
                      Divider(color: c.divider, thickness: 1),
                      SizedBox(height: _sh * 0.018),
                      Row(
                        children: [
                          _perfMiniStat('Avg Score', stats.avgScoreLabel, null),
                          _perfDivider(),
                          _perfMiniStat(
                            'Best Round',
                            stats.bestRoundScore > 0
                                ? '${stats.bestRoundScore}'
                                : '-',
                            stats.bestRoundScore > 0
                                ? const Color(0xFF8FD44E)
                                : null,
                          ),
                          _perfDivider(),
                          _perfMiniStat(
                              'Rounds', '${stats.totalRounds}', null),
                          _perfDivider(),
                          _perfMiniStat('Birdies',
                              '${stats.totalBirdies}', const Color(0xFF8FD44E)),
                        ],
                      ),
                    ],
                  )
                : _buildEmptyPerformance(c),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPerformance(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded,
              color: c.tertiaryText,
              size: (_sw * 0.08).clamp(28.0, 36.0)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete rounds to see your handicap and performance stats.',
              style: TextStyle(color: c.secondaryText, fontSize: _labelSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandicapRing(AppColors c, double handicap) {
    final ringSize = (_sw * 0.28).clamp(100.0, 130.0);
    final progress = (handicap.clamp(0, 54) / 54.0);
    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: CustomPaint(
        painter: _HandicapArcPainter(
          progress: progress,
          accentColor: c.accent,
          trackColor: c.iconContainerBg,
          labelColor: c.primaryText,
          subColor: c.secondaryText,
          handicap: handicap,
        ),
      ),
    );
  }

  Widget _perfMiniStat(String label, String value, Color? valueColor) {
    final c = AppColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontFamily: 'Nunito',
              color: valueColor ?? c.primaryText,
              fontSize: _bodySize * 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.tertiaryText,
              fontSize: _labelSize * 0.9,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfDivider() {
    final c = AppColors.of(context);
    return Container(width: 1, height: 32, color: c.divider);
  }

  // ── Quick Stats ───────────────────────────────────────────────────────────
  Widget _buildQuickStats(AppStats stats) {
    final hasData = stats.totalRounds > 0;
    final tiles = [
      _StatTileData(
        label: 'Fairways Hit',
        value: hasData ? '${stats.fairwaysHitPct.toStringAsFixed(0)}%' : '-',
        subtitle: 'Par 4 & 5 holes',
        icon: Icons.straighten_rounded,
        color: const Color(0xFF6DBD35),
      ),
      _StatTileData(
        label: 'Greens in Reg.',
        value: hasData ? '${stats.girPct.toStringAsFixed(0)}%' : '-',
        subtitle: 'All holes',
        icon: Icons.flag_rounded,
        color: const Color(0xFFFFB74D),
      ),
      _StatTileData(
        label: 'Avg Putts',
        value: hasData ? stats.avgPutts.toStringAsFixed(1) : '-',
        subtitle: 'Per hole',
        icon: Icons.sports_golf_rounded,
        color: const Color(0xFFFFB74D),
      ),
      _StatTileData(
        label: 'Birdies',
        value: hasData ? '${stats.totalBirdies}' : '-',
        subtitle: 'All rounds',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFCE93D8),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _hPad),
          child: _sectionTitle('Quick Stats'),
        ),
        SizedBox(height: _sh * 0.016),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _hPad),
          child: GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: (_sh * 0.155).clamp(130.0, 155.0),
            ),
            itemBuilder: (_, i) => _buildStatTile(tiles[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(_StatTileData stat) {
    final c = AppColors.of(context);
    double progress = 0.0;
    final raw = double.tryParse(stat.value.replaceAll('%', '')) ?? 0;
    if (stat.label == 'Fairways Hit' || stat.label == 'Greens in Reg.') {
      progress = (raw / 100).clamp(0.0, 1.0);
    } else if (stat.label == 'Avg Putts') {
      progress = (1.0 - ((raw - 1.5) / 1.5)).clamp(0.0, 1.0);
    } else if (stat.label == 'Birdies') {
      progress = (raw / 18).clamp(0.0, 1.0);
    }

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((_sw * 0.042).clamp(14.0, 18.0)),
      child: Stack(
          children: [
            Positioned(
              top: 0, left: 0,
              child: Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: stat.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(48),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: (_sw * 0.092).clamp(32.0, 40.0),
                  height: (_sw * 0.092).clamp(32.0, 40.0),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: (_sw * 0.050).clamp(17.0, 22.0)),
                ),
                const Spacer(),
                Text(stat.value,
                    style: TextStyle(fontFamily: 'Nunito', color: c.primaryText,
                        fontSize: (_sw * 0.065).clamp(22.0, 28.0), fontWeight: FontWeight.w800, height: 1.1)),
                Text(stat.label,
                    style: TextStyle(color: c.secondaryText, fontSize: _labelSize, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(stat.subtitle,
                    style: TextStyle(color: const Color(0xFF8FD44E).withValues(alpha: 0.8), fontSize: _labelSize * 0.88)),
              ],
            ),
            Positioned(
              top: 0, right: 0,
              child: SizedBox(
                width: 46, height: 46,
                child: CustomPaint(painter: _ProgressArcPainter(progress: progress, color: stat.color)),
              ),
            ),
          ],
        ),
    );
  }

  // ── Nearby Courses ────────────────────────────────────────────────────────
  Widget _buildNearbyCourses() {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _hPad),
          child: Row(
            children: [
              Expanded(child: _sectionTitle('Nearby Courses')),
              GestureDetector(
                onTap: _showLocationPicker,
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: c.accent, size: _labelSize),
                    const SizedBox(width: 3),
                    Text(
                      _locationName ?? 'Near you',
                      style: TextStyle(color: c.accent, fontSize: _labelSize),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_rounded, color: c.accent, size: _labelSize * 0.9),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _sh * 0.014),
        if (_loadingNearby)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _hPad),
            child: Container(
              height: 100,
              decoration: ShapeDecoration(
                gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(48),
                  side: BorderSide(color: c.cardBorder),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        strokeWidth: 2, color: c.accent),
                    const SizedBox(height: 10),
                    Text('Finding courses near you…',
                        style: TextStyle(
                            color: c.secondaryText,
                            fontSize: _labelSize)),
                  ],
                ),
              ),
            ),
          )
        else if (_nearbyCourses.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _hPad),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(48),
                  side: BorderSide(color: c.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off_rounded,
                      color: c.tertiaryText,
                      size: (_sw * 0.07).clamp(24.0, 30.0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _userPosition == null
                          ? 'Enable location to see nearby golf courses'
                          : 'No golf courses found within 25 km',
                      style: TextStyle(
                          color: c.secondaryText, fontSize: _bodySize * 0.9),
                    ),
                  ),
                  if (_userPosition == null)
                    GestureDetector(
                      onTap: _loadNearbyCourses,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.accentBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.accentBorder),
                        ),
                        child: Text('Allow',
                            style: TextStyle(
                                color: c.accent,
                                fontSize: _labelSize,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: (_sh * 0.165).clamp(130.0, 160.0),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: _hPad),
              physics: const BouncingScrollPhysics(),
              itemCount: _nearbyCourses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) =>
                  _buildNearbyCourseCard(_nearbyCourses[i], c),
            ),
          ),
      ],
    );
  }

  Widget _buildNearbyCourseCard(GolfCourseDetail course, AppColors c) {
    final cardW = (_sw * 0.60).clamp(200.0, 260.0);
    return GestureDetector(
      onTap: () {
        // Open Start Round with this course pre-filled
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _PrefilledStartRound(
              courseName: course.name,
              location: course.address,
              userPosition: _userPosition,
              customLat: _customLat,
              customLng: _customLng,
            ),
          ),
        );
      },
      child: Container(
        width: cardW,
        decoration: ShapeDecoration(
          gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(48),
            side: BorderSide(color: c.cardBorder),
          ),
          shadows: c.cardShadow,
        ),
        padding: EdgeInsets.all((_sw * 0.04).clamp(12.0, 18.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: (_sw * 0.10).clamp(34.0, 42.0),
                  height: (_sw * 0.10).clamp(34.0, 42.0),
                  decoration: BoxDecoration(
                    color: c.accentBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.accentBorder),
                  ),
                  child: Icon(Icons.golf_course_rounded,
                      color: c.accent,
                      size: (_sw * 0.05).clamp(16.0, 22.0)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A9E1F), Color(0xFF7BC344)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_golf_rounded,
                          color: Colors.white, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        'Play',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _labelSize * 0.9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              course.name,
              style: TextStyle(fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: _bodySize,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (course.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      color: c.tertiaryText, size: _labelSize),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      course.address,
                      style: TextStyle(
                          color: c.tertiaryText, fontSize: _labelSize),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final c = AppColors.of(context);
    return Text(
      title,
      style: TextStyle(fontFamily: 'Nunito',
        color: c.primaryText,
        fontSize: (_sw * 0.048).clamp(16.0, 20.0),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View-model helpers
// ---------------------------------------------------------------------------
class _RoundCardData {
  final String course;
  final String location;
  final int score;
  final int par;
  final int holesPlayed;
  final int totalHoles;
  final String timeAgo;
  final bool isActive;
  final List<HoleScore> scores;

  const _RoundCardData({
    required this.course,
    required this.location,
    required this.score,
    required this.par,
    required this.holesPlayed,
    required this.totalHoles,
    required this.timeAgo,
    required this.isActive,
    this.scores = const [],
  });

  factory _RoundCardData.fromRound(Round r,
      {required bool isActive, required String timeAgo}) {
    return _RoundCardData(
      course: r.courseName,
      location: r.courseLocation,
      score: r.totalScore,
      par: r.totalPar,
      holesPlayed: r.holesPlayed,
      totalHoles: r.totalHoles,
      timeAgo: timeAgo,
      isActive: isActive,
      scores: r.scores,
    );
  }

  int get diff => score - par;
  String get diffLabel =>
      diff == 0 ? 'E' : diff > 0 ? '+$diff' : '$diff';
}

class _StatTileData {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatTileData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// _PrefilledStartRound — StartRoundScreen with course pre-filled from nearby
// ---------------------------------------------------------------------------
class _PrefilledStartRound extends StatefulWidget {
  final String courseName;
  final String location;
  final Position? userPosition;
  final double? customLat;
  final double? customLng;
  const _PrefilledStartRound({
    required this.courseName,
    required this.location,
    this.userPosition,
    this.customLat,
    this.customLng,
  });

  @override
  State<_PrefilledStartRound> createState() => _PrefilledStartRoundState();
}

class _PrefilledStartRoundState extends State<_PrefilledStartRound> {
  @override
  Widget build(BuildContext context) {
    // Push StartRoundScreen immediately after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StartRoundScreen(
            initialCourseName: widget.courseName,
            initialLocation: widget.location,
            initialPosition: widget.userPosition,
            initialCustomLat: widget.customLat,
            initialCustomLng: widget.customLng,
          ),
        ),
      );
    });
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// _StartModeSheet — FAB sheet to choose round type
// ---------------------------------------------------------------------------
class _StartModeSheet extends StatefulWidget {
  final AppColors c;
  final double sw, sh;
  final Position? userPosition;
  final double? customLat;
  final double? customLng;
  final String? locationName;

  const _StartModeSheet({
    required this.c,
    required this.sw,
    required this.sh,
    this.userPosition,
    this.customLat,
    this.customLng,
    this.locationName,
  });

  @override
  State<_StartModeSheet> createState() => _StartModeSheetState();
}

class _StartModeSheetState extends State<_StartModeSheet> {
  AppColors get c  => widget.c;
  double    get sw => widget.sw;
  double    get sh => widget.sh;

  @override
  Widget build(BuildContext context) {
    final body  = (sw * 0.038).clamp(14.0, 17.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final hPad  = (sw * 0.065).clamp(22.0, 32.0);

    return Container(
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: c.cardBorder)),
      ),
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, sh * 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: c.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start Activity',
            style: TextStyle(
                fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: (sw * 0.052).clamp(18.0, 22.0),
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: sh * 0.008),
          Text(
            'What are you playing today?',
            style: TextStyle(color: c.tertiaryText, fontSize: label),
          ),
          SizedBox(height: sh * 0.028),

          // Regular Round
          _ModeOption(
            icon: Icons.sports_golf_rounded,
            color: const Color(0xFF5A9E1F),
            title: 'Regular Round',
            subtitle: 'Score a round — counts toward your handicap & stats',
            body: body,
            label: label,
            c: c,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StartRoundScreen(
                        initialPosition: widget.userPosition,
                        initialCustomLat: widget.customLat,
                        initialCustomLng: widget.customLng,
                        initialLocation: widget.locationName)),
              );
            },
          ),
          SizedBox(height: sh * 0.014),

          // Practice Round
          _ModeOption(
            icon: Icons.flag_rounded,
            color: const Color(0xFF6DBD35),
            title: 'Practice Round',
            subtitle: 'Scored round that stays in your Practice tab',
            body: body,
            label: label,
            c: c,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StartRoundScreen(
                        isPractice: true,
                        initialPosition: widget.userPosition,
                        initialCustomLat: widget.customLat,
                        initialCustomLng: widget.customLng,
                        initialLocation: widget.locationName)),
              );
            },
          ),
          SizedBox(height: sh * 0.014),

          // Tournament Round
          _TournamentModeOption(
            c: c, sw: sw, sh: sh, body: body, label: label,
            userPosition: widget.userPosition,
            customLat: widget.customLat,
            customLng: widget.customLng,
            locationName: widget.locationName,
          ),
        ],
      ),
    );
  }
}

// ── Single mode row ────────────────────────────────────────────────────────
class _ModeOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double body;
  final double label;
  final AppColors c;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.label,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: ShapeDecoration(
          gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(48),
            side: BorderSide(color: c.cardBorder),
          ),
          shadows: c.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          color: c.primaryText,
                          fontSize: body,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: c.tertiaryText, fontSize: label * 0.92)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.tertiaryText, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Tournament mode — loads tournaments to show picker ────────────────────
class _TournamentModeOption extends StatelessWidget {
  final AppColors c;
  final double sw, sh, body, label;
  final Position? userPosition;
  final double? customLat;
  final double? customLng;
  final String? locationName;

  const _TournamentModeOption({
    required this.c,
    required this.sw,
    required this.sh,
    required this.body,
    required this.label,
    this.userPosition,
    this.customLat,
    this.customLng,
    this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tournament>>(
      stream: TournamentService.tournamentsStream(),
      builder: (context, snap) {
        final tournaments = snap.data ?? [];
        final enabled = tournaments.isNotEmpty;
        final color = enabled
            ? const Color(0xFFFFB74D)
            : c.tertiaryText;

        return GestureDetector(
          onTap: enabled
              ? () => _pickTournament(context, tournaments)
              : () => _promptCreateTournament(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: ShapeDecoration(
              gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(48),
                side: BorderSide(color: c.cardBorder),
              ),
              shadows: c.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.emoji_events_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tournament Round',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              color: c.primaryText,
                              fontSize: body,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        enabled
                            ? 'Add a scored round to one of your tournaments'
                            : 'Create a tournament first in the Rounds tab',
                        style: TextStyle(
                            color: c.tertiaryText, fontSize: label * 0.92),
                      ),
                    ],
                  ),
                ),
                Icon(
                  enabled
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                  color: c.tertiaryText,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickTournament(BuildContext context, List<Tournament> tournaments) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _TournamentPickerInline(
            c: c, sw: sw, sh: sh, tournaments: tournaments,
            userPosition: userPosition,
            customLat: customLat,
            customLng: customLng,
            locationName: locationName,
          ),
    );
  }

  void _promptCreateTournament(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Go to Rounds → Tournaments and create a tournament first.'),
        backgroundColor: const Color(0xFF5A9E1F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Inline tournament picker (reused from tournament_screen logic) ─────────
class _TournamentPickerInline extends StatefulWidget {
  final AppColors c;
  final double sw, sh;
  final List<Tournament> tournaments;
  final Position? userPosition;
  final double? customLat;
  final double? customLng;
  final String? locationName;

  const _TournamentPickerInline({
    required this.c,
    required this.sw,
    required this.sh,
    required this.tournaments,
    this.userPosition,
    this.customLat,
    this.customLng,
    this.locationName,
  });

  @override
  State<_TournamentPickerInline> createState() =>
      _TournamentPickerInlineState();
}

class _TournamentPickerInlineState extends State<_TournamentPickerInline> {
  String? _selectedId;

  AppColors get c  => widget.c;
  double    get sw => widget.sw;
  double    get sh => widget.sh;

  @override
  Widget build(BuildContext context) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final hPad  = (sw * 0.065).clamp(22.0, 32.0);

    return Container(
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: c.cardBorder)),
      ),
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, sh * 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: c.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Select Tournament',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: (sw * 0.052).clamp(18.0, 22.0),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: sh * 0.008),
          Text('Which tournament is this round for?',
              style: TextStyle(color: c.tertiaryText, fontSize: label)),
          SizedBox(height: sh * 0.020),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sh * 0.35),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.tournaments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final t = widget.tournaments[i];
                final sel = _selectedId == t.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedId = t.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? c.accentBg : c.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? c.accentBorder : c.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sel
                              ? Icons.check_circle_rounded
                              : Icons.emoji_events_outlined,
                          color: sel ? c.accent : c.tertiaryText,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(t.name,
                              style: TextStyle(
                                  color: sel ? c.accent : c.primaryText,
                                  fontSize: label,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                        ),
                        Text(
                          '${t.roundIds.length} round${t.roundIds.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              color: c.tertiaryText, fontSize: label * 0.9),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: sh * 0.024),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedId == null ? null : _proceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.white,
                disabledBackgroundColor: c.fieldBg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Text('Continue to Round Setup',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: body,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _proceed() {
    final tournId = _selectedId!;
    Navigator.popUntil(context, (r) => r.isFirst); // close both sheets
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartRoundScreen(
          tournamentId: tournId,
          initialPosition: widget.userPosition,
          initialCustomLat: widget.customLat,
          initialCustomLng: widget.customLng,
          initialLocation: widget.locationName,
          onComplete: (roundId) =>
              TournamentService.addRound(tournId, roundId),
        ),
      ),
    );
  }
}

// ── Painters ────────────────────────────────────────────────────────────────

class _CourseSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.75);
    path.cubicTo(size.width * 0.25, size.height * 0.55,
        size.width * 0.50, size.height * 0.65, size.width * 0.70, size.height * 0.50);
    path.cubicTo(size.width * 0.82, size.height * 0.42,
        size.width * 0.90, size.height * 0.48, size.width, size.height * 0.44);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.07)..style = PaintingStyle.fill;

    void drawFlag(double px, double py, double flagH) {
      canvas.drawLine(Offset(px, py), Offset(px, py + flagH), stroke);
      canvas.drawPath(Path()..moveTo(px, py)..lineTo(px + 10, py + 5)..lineTo(px, py + 10)..close(), fill);
    }
    drawFlag(size.width * 0.68, size.height * 0.30, size.height * 0.22);
    drawFlag(size.width * 0.87, size.height * 0.25, size.height * 0.21);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ProgressArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = 2.8;
    const sweepTotal = 3.8;
    final rect = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    canvas.drawArc(rect, startAngle, sweepTotal, false,
        Paint()..color = color.withValues(alpha: 0.18)..strokeWidth = 3.5
          ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    if (progress > 0.01) {
      canvas.drawArc(rect, startAngle, sweepTotal * progress, false,
          Paint()..color = color.withValues(alpha: 0.85)..strokeWidth = 3.5
            ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _HandicapArcPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color trackColor;
  final Color labelColor;
  final Color subColor;
  final double handicap;
  const _HandicapArcPainter({required this.progress, required this.accentColor,
      required this.trackColor, required this.labelColor, required this.subColor, required this.handicap});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = 2.36;
    const sweepAngle = 4.71;

    canvas.drawArc(rect, startAngle, sweepAngle, false,
        Paint()..color = trackColor..strokeWidth = size.width * 0.075
          ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    if (progress > 0.005) {
      final gradPaint = Paint()
        ..shader = SweepGradient(
          colors: [accentColor, accentColor.withValues(alpha: 0.4)],
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle * progress,
        ).createShader(rect)
        ..strokeWidth = size.width * 0.075
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle * progress, false, gradPaint);

      final endAngle = startAngle + sweepAngle * progress;
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);
      canvas.drawCircle(Offset(dotX, dotY), size.width * 0.055,
          Paint()..color = accentColor.withValues(alpha: 0.28));
      canvas.drawCircle(Offset(dotX, dotY), size.width * 0.030,
          Paint()..color = accentColor);
    }

    final label = handicap <= 0 ? '+${(-handicap).toStringAsFixed(1)}' : handicap.toStringAsFixed(1);
    final vp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(fontFamily: 'Nunito',
          color: labelColor, fontSize: size.width * 0.19, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    vp.paint(canvas, Offset(center.dx - vp.width / 2, center.dy - vp.height * 0.62));

    final sp = TextPainter(
      text: TextSpan(text: 'handicap', style: TextStyle(
          color: subColor, fontSize: size.width * 0.095, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    sp.paint(canvas, Offset(center.dx - sp.width / 2, center.dy + vp.height * 0.22));
  }

  @override
  bool shouldRepaint(covariant _HandicapArcPainter old) => old.progress != progress;
}
