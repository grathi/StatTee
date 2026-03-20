import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/round.dart';
import '../services/places_service.dart';
import '../services/round_service.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import 'start_round_screen.dart';
import 'scorecard_screen.dart';
import 'rounds_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: c.scaffoldBg,
      body: IndexedStack(
        index: _navIndex,
        children: const [
          _HomeTab(),
          RoundsScreen(),
          StatsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(c),
    );
  }

  Widget _buildBottomNav(AppColors c) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final labelSize = (sw * 0.030).clamp(11.0, 13.0);

    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.golf_course_rounded, Icons.golf_course_outlined, 'Rounds'),
      (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Stats'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: c.navBg,
            border: Border(top: BorderSide(color: c.navBorder, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: (sh * 0.075).clamp(56.0, 72.0),
              child: Row(
                children: List.generate(items.length, (i) {
                  final isActive = _navIndex == i;
                  final (activeIcon, inactiveIcon, label) = items[i];
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _navIndex = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isActive ? activeIcon : inactiveIcon,
                              key: ValueKey(isActive),
                              color: isActive ? c.accent : c.navInactive,
                              size: (sw * 0.060).clamp(22.0, 26.0),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            style: TextStyle(
                              color: isActive ? c.accent : c.navInactive,
                              fontSize: labelSize * 0.88,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isActive ? 16 : 0,
                            height: 3,
                            decoration: BoxDecoration(
                              color: c.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  Position? _userPosition;
  String?   _locationName;
  List<GolfCourseDetail> _nearbyCourses = [];
  bool _loadingNearby = false;

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
    setState(() => _loadingNearby = true);
    final pos = await PlacesService.getCurrentLocation();
    if (!mounted) return;
    if (pos == null) {
      setState(() => _loadingNearby = false);
      return;
    }
    final name    = await PlacesService.getLocationName(pos);
    final courses = await PlacesService.nearbyGolfCourses(pos);
    if (!mounted) return;
    setState(() {
      _userPosition  = pos;
      _locationName  = name;
      _nearbyCourses = courses;
      _loadingNearby = false;
    });
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
    if (diff < 0) return const Color(0xFF818CF8);
    if (diff == 0) return const Color(0xFF64B5F6);
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
                                  SizedBox(height: _sh * 0.030),
                                  _buildRecentRounds(activeRound, recentRounds),
                                  SizedBox(height: _sh * 0.030),
                                  _buildPerformanceSummary(stats),
                                  SizedBox(height: _sh * 0.030),
                                  _buildQuickStats(stats),
                                  SizedBox(height: _sh * 0.030),
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
                colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.5),
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
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.sports_golf_rounded,
                        color: c.accent, size: _labelSize * 1.1),
                    const SizedBox(width: 2),
                    Text(
                      'Play | Track | Improve',
                      style: TextStyle(
                          color: c.tertiaryText, fontSize: _labelSize),
                    ),
                  ],
                ),
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
              builder: (_) => const StartRoundScreen(),
            ));
          }
        },
        child: Container(
          width: double.infinity,
          height: (_sh * 0.195).clamp(150.0, 200.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasActive
                  ? const [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)]
                  : const [Color(0xFF1E1B4B), Color(0xFF4F46E5), Color(0xFF6366F1)],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: (hasActive
                        ? const Color(0xFF4338CA)
                        : const Color(0xFF4F46E5))
                    .withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24, top: -24,
                child: Container(
                  width: (_sw * 0.38).clamp(120.0, 170.0),
                  height: (_sw * 0.38).clamp(120.0, 170.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 24, bottom: -30,
                child: Container(
                  width: (_sw * 0.22).clamp(70.0, 100.0),
                  height: (_sw * 0.22).clamp(70.0, 100.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                right: (_sw * 0.065).clamp(20.0, 30.0),
                top: 0, bottom: 0,
                child: Center(
                  child: Icon(
                    hasActive
                        ? Icons.play_circle_outline_rounded
                        : Icons.sports_golf_rounded,
                    color: Colors.white.withValues(alpha: 0.20),
                    size: (_sw * 0.22).clamp(70.0, 90.0),
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
                      style: TextStyle(fontFamily: 'Nunito',
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
                onTap: () {},
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
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
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
      decoration: BoxDecoration(
        color: round.isActive
            ? c.cardBg.withValues(alpha: c.isDark ? 0.11 : 1.0)
            : c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: round.isActive ? c.accentBorder : c.cardBorder,
        ),
        boxShadow: round.isActive ? [] : c.cardShadow,
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
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.cardBorder),
              boxShadow: c.cardShadow,
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
                          _buildHandicapRing(stats.handicapIndex, 54.0),
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
                                ? const Color(0xFF818CF8)
                                : null,
                          ),
                          _perfDivider(),
                          _perfMiniStat(
                              'Rounds', '${stats.totalRounds}', null),
                          _perfDivider(),
                          _perfMiniStat('Birdies',
                              '${stats.totalBirdies}', const Color(0xFF818CF8)),
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

  Widget _buildHandicapRing(double handicap, double maxHandicap) {
    final c = AppColors.of(context);
    final progress = (1 - (handicap / maxHandicap)).clamp(0.0, 1.0);
    final size = (_sw * 0.22).clamp(72.0, 90.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: size * 0.08,
              backgroundColor: c.iconContainerBg,
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF818CF8)),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontFamily: 'Nunito',
                  color: const Color(0xFF818CF8),
                  fontSize: _bodySize * 0.9,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                'Better\nthan avg',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.tertiaryText,
                  fontSize: _labelSize * 0.85,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
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
        color: const Color(0xFF34D399),
      ),
      _StatTileData(
        label: 'Greens in Reg.',
        value: hasData ? '${stats.girPct.toStringAsFixed(0)}%' : '-',
        subtitle: 'All holes',
        icon: Icons.flag_rounded,
        color: const Color(0xFF64B5F6),
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
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
      ),
      padding: EdgeInsets.all((_sw * 0.042).clamp(14.0, 18.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: (_sw * 0.092).clamp(32.0, 40.0),
            height: (_sw * 0.092).clamp(32.0, 40.0),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon,
                color: stat.color,
                size: (_sw * 0.050).clamp(17.0, 22.0)),
          ),
          const Spacer(),
          Text(
            stat.value,
            style: TextStyle(fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: (_sw * 0.065).clamp(22.0, 28.0),
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            stat.label,
            style: TextStyle(
              color: c.secondaryText,
              fontSize: _labelSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.subtitle,
            style: TextStyle(
              color: const Color(0xFF818CF8).withValues(alpha: 0.8),
              fontSize: _labelSize * 0.88,
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
              if (_userPosition != null)
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: c.accent, size: _labelSize),
                    const SizedBox(width: 3),
                    Text(
                      _locationName ?? 'Near you',
                      style: TextStyle(color: c.accent, fontSize: _labelSize),
                    ),
                  ],
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
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.cardBorder),
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
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.cardBorder),
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
            ),
          ),
        );
      },
      child: Container(
        width: cardW,
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
          boxShadow: c.cardShadow,
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
                      colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
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

  const _RoundCardData({
    required this.course,
    required this.location,
    required this.score,
    required this.par,
    required this.holesPlayed,
    required this.totalHoles,
    required this.timeAgo,
    required this.isActive,
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
  const _PrefilledStartRound(
      {required this.courseName, required this.location});

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
          ),
        ),
      );
    });
    return const SizedBox.shrink();
  }
}
