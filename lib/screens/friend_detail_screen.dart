import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/friend_profile.dart';
import '../models/round.dart';
import '../services/friends_service.dart';
import '../services/stats_service.dart';
import '../services/pressure_score_service.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FriendDetailScreen extends StatefulWidget {
  const FriendDetailScreen({super.key, required this.friend});

  final FriendProfile friend;

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    try {
      final meUid  = FirebaseAuth.instance.currentUser!.uid;
      final friend = widget.friend;

      final results = await Future.wait([
        FriendsService.loadStatsForUser(friend.uid),
        FriendsService.loadStatsForUser(meUid),
        FriendsService.loadRecentRoundsForUser(friend.uid, limit: 50),
        FriendsService.loadRecentRoundsForUser(meUid, limit: 50),
      ]);

      return _DetailData(
        friendStats: results[0] as AppStats,
        myStats: results[1] as AppStats,
        recentRounds: results[2] as List<Round>,
        friendRounds: results[2] as List<Round>,
        myRounds: results[3] as List<Round>,
      );
    } catch (e, st) {
      debugPrint('[FriendDetail] _load error: $e\n$st');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final sw    = MediaQuery.of(context).size.width;
    final sh    = MediaQuery.of(context).size.height;
    final hPad  = (sw * 0.055).clamp(18.0, 28.0);
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: c.bgGradient,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: FutureBuilder<_DetailData>(
            future: _future,
            builder: (context, snap) {
              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                color: c.primaryText, size: 20),
                          ),
                          const SizedBox(width: 14),
                          _AvatarLg(
                              url: widget.friend.avatarUrl,
                              name: widget.friend.displayName),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.friend.displayName,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    color: c.primaryText,
                                    fontSize: (sw * 0.052).clamp(18.0, 24.0),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (snap.data != null)
                                  Text(
                                    '${snap.data!.friendStats.totalRounds} rounds played',
                                    style: TextStyle(
                                        color: c.tertiaryText,
                                        fontSize: label),
                                  ),
                              ],
                            ),
                          ),
                          // Remove friend
                          GestureDetector(
                            onTap: () => _confirmRemove(context, c, body, label),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: c.accentBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.accentBorder, width: 1.2),
                              ),
                              child: Icon(Icons.person_remove_outlined,
                                  color: c.accent, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (snap.connectionState == ConnectionState.waiting)
                    SliverFillRemaining(
                      child: Center(
                          child: CircularProgressIndicator(
                              color: c.accent, strokeWidth: 2)),
                    )
                  else if (snap.hasError)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Could not load data',
                                style: TextStyle(color: c.tertiaryText)),
                            if (kDebugMode) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text('${snap.error}',
                                    style: TextStyle(color: c.tertiaryText, fontSize: 11),
                                    textAlign: TextAlign.center),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => setState(() { _future = _load(); }),
                              child: Text('Retry', style: TextStyle(color: c.accent)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Stats row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, 0),
                        child: _StatsRow(
                            c: c, sw: sw, body: body, label: label,
                            stats: snap.data!.friendStats),
                      ),
                    ),

                    // Rivalry chart
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, 0),
                        child: _RivalryChart(
                          c: c,
                          body: body,
                          label: label,
                          friendName: widget.friend.displayName,
                          myStats: snap.data!.myStats,
                          friendStats: snap.data!.friendStats,
                          myRounds: snap.data!.myRounds,
                          friendRounds: snap.data!.friendRounds,
                        ),
                      ),
                    ),

                    // Recent rounds
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            hPad, sh * 0.022, hPad, 0),
                        child: Text('Recent Rounds',
                            style: TextStyle(
                                color: c.primaryText,
                                fontSize: body,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (snap.data!.recentRounds.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              hPad, sh * 0.012, hPad, 0),
                          child: Text('No completed rounds yet',
                              style: TextStyle(
                                  color: c.tertiaryText, fontSize: body)),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final r = snap.data!.recentRounds[i];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                  hPad, i == 0 ? sh * 0.012 : 8, hPad, 0),
                              child: _RoundRow(
                                  c: c, body: body, label: label, round: r),
                            );
                          },
                          childCount: snap.data!.recentRounds.length,
                        ),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: sh * 0.12)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, AppColors c, double body, double label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: ShapeDecoration(
          color: c.cardBg,
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Remove Friend?',
                style: TextStyle(
                    color: c.primaryText,
                    fontSize: body * 1.1,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '${widget.friend.displayName} will be removed from your friends list.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.secondaryText, fontSize: body),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: ShapeDecoration(
                        color: c.fieldBg,
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: c.fieldBorder),
                        ),
                      ),
                      child: Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: c.secondaryText,
                                  fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await FriendsService.declineOrRemove(widget.friend.uid);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.15),
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: Color(0xFFEF4444), width: 0.5),
                        ),
                      ),
                      child: const Center(
                          child: Text('Remove',
                              style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow(
      {required this.c,
      required this.sw,
      required this.body,
      required this.label,
      required this.stats});

  final AppColors c;
  final double sw, body, label;
  final AppStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (icon: Icons.track_changes_rounded,
       color: const Color(0xFF3B82F6),
       value: stats.handicapLabel,
       lbl: 'Handicap'),
      (icon: Icons.sports_golf_rounded,
       color: const Color(0xFF7BE0AD),
       value: stats.avgScoreLabel,
       lbl: 'Avg Score'),
      (icon: Icons.emoji_events_rounded,
       color: const Color(0xFFF59E0B),
       value: '${stats.totalBirdies}',
       lbl: 'Birdies'),
      (icon: Icons.golf_course_rounded,
       color: const Color(0xFF8B5CF6),
       value: '${stats.totalRounds}',
       lbl: 'Rounds'),
    ];

    return Row(
      children: tiles
          .map((t) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: const Color(0xFFE7E5E5)),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: t.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(t.icon, color: t.color, size: body),
                      ),
                      const SizedBox(height: 6),
                      Text(t.value,
                          style: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontSize: body * 1.05,
                              fontWeight: FontWeight.w800)),
                      Text(t.lbl,
                          style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: label * 0.9)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Rivalry Chart (replaces Head-to-Head) ─────────────────────────────────────

class _RivalryChart extends StatelessWidget {
  const _RivalryChart({
    required this.c,
    required this.body,
    required this.label,
    required this.friendName,
    required this.myStats,
    required this.friendStats,
    required this.myRounds,
    required this.friendRounds,
  });

  final AppColors c;
  final double body, label;
  final String friendName;
  final AppStats myStats, friendStats;
  final List<Round> myRounds, friendRounds;

  @override
  Widget build(BuildContext context) {
    int myWins = 0, theirWins = 0;
    void tally(bool iWin, bool theyWin) {
      if (iWin) myWins++;
      if (theyWin) theirWins++;
    }

    final hcpIWin = myStats.handicapIndex != null &&
        friendStats.handicapIndex != null &&
        myStats.handicapIndex! < friendStats.handicapIndex!;
    final hcpTheyWin = myStats.handicapIndex != null &&
        friendStats.handicapIndex != null &&
        friendStats.handicapIndex! < myStats.handicapIndex!;
    tally(hcpIWin, hcpTheyWin);
    tally(myStats.totalBirdies > friendStats.totalBirdies,
        friendStats.totalBirdies > myStats.totalBirdies);
    tally(myStats.girPct > friendStats.girPct,
        friendStats.girPct > myStats.girPct);
    tally(myStats.avgPutts < friendStats.avgPutts,
        friendStats.avgPutts < myStats.avgPutts);

    final myPressure = PressureScoreService.compute(myRounds);
    final friendPressure = PressureScoreService.compute(friendRounds);
    final myPS = myPressure.compositeScore;
    final themPS = friendPressure.compositeScore;
    if (myRounds.length >= 5 && friendRounds.length >= 5) {
      tally(myPS > themPS, themPS > myPS);
    }

    String badgeText;
    if (myWins > theirWins) {
      badgeText = 'You lead $myWins–$theirWins';
    } else if (theirWins > myWins) {
      badgeText = '$friendName leads $theirWins–$myWins';
    } else {
      badgeText = 'Tied $myWins–$theirWins';
    }
    final iLeading = myWins > theirWins;
    final isTied = myWins == theirWins;

    // Course duel
    final myCourses = <String, List<Round>>{};
    final friendCourses = <String, List<Round>>{};
    for (final r in myRounds) myCourses.putIfAbsent(r.courseName, () => []).add(r);
    for (final r in friendRounds) friendCourses.putIfAbsent(r.courseName, () => []).add(r);
    final sharedCourses = myCourses.keys.where(friendCourses.containsKey).toList();
    String? duelCourse;
    if (sharedCourses.isNotEmpty) {
      sharedCourses.sort((a, b) =>
          ((myCourses[b]?.length ?? 0) + (friendCourses[b]?.length ?? 0))
              .compareTo((myCourses[a]?.length ?? 0) + (friendCourses[a]?.length ?? 0)));
      duelCourse = sharedCourses.first;
    }
    double _avgScore(List<Round> rs) =>
        rs.isEmpty ? 0 : rs.fold(0.0, (s, r) => s + r.scoreDiff) / rs.length;

    final rows = [
      _RivalryMetric(
        label: 'Handicap',
        myVal: myStats.handicapLabel,
        theirVal: friendStats.handicapLabel,
        myScore: myStats.handicapIndex != null ? -myStats.handicapIndex! : 0,
        theirScore: friendStats.handicapIndex != null ? -friendStats.handicapIndex! : 0,
        lowerIsBetter: true,
      ),
      _RivalryMetric(
        label: 'Avg Score',
        myVal: myStats.avgScoreLabel,
        theirVal: friendStats.avgScoreLabel,
        myScore: myStats.avgScore,
        theirScore: friendStats.avgScore,
        lowerIsBetter: true,
      ),
      _RivalryMetric(
        label: 'Birdies',
        myVal: '${myStats.totalBirdies}',
        theirVal: '${friendStats.totalBirdies}',
        myScore: myStats.totalBirdies.toDouble(),
        theirScore: friendStats.totalBirdies.toDouble(),
        lowerIsBetter: false,
      ),
      _RivalryMetric(
        label: 'GIR %',
        myVal: '${myStats.girPct.toStringAsFixed(0)}%',
        theirVal: '${friendStats.girPct.toStringAsFixed(0)}%',
        myScore: myStats.girPct,
        theirScore: friendStats.girPct,
        lowerIsBetter: false,
      ),
      _RivalryMetric(
        label: 'Avg Putts',
        myVal: myStats.avgPutts.toStringAsFixed(1),
        theirVal: friendStats.avgPutts.toStringAsFixed(1),
        myScore: myStats.avgPutts,
        theirScore: friendStats.avgPutts,
        lowerIsBetter: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lead badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: isTied
                  ? const Color(0xFFFEF3C7)
                  : iLeading
                      ? const Color(0xFF7BE0AD).withValues(alpha: 0.18)
                      : const Color(0xFFE5D0E3).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isTied
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                    : iLeading
                        ? const Color(0xFF7BE0AD).withValues(alpha: 0.6)
                        : const Color(0xFFE5D0E3),
                width: 1.2,
              ),
              boxShadow: iLeading
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7BE0AD).withValues(alpha: 0.30),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: isTied
                    ? const Color(0xFFF59E0B)
                    : iLeading
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF7C3AED),
                fontSize: label * 1.05,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Rivalry chart card
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(28),
              side: const BorderSide(color: Color(0xFFE7E5E5)),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('You',
                          style: TextStyle(
                              color: const Color(0xFF16A34A),
                              fontSize: label * 1.05,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.left),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('vs',
                          style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: label,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ),
                    Expanded(
                      child: Text(friendName,
                          style: TextStyle(
                              color: const Color(0xFF64748B),
                              fontSize: label * 1.05,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFE7E5E5), height: 1),
              const SizedBox(height: 8),
              ...rows.map((r) => _buildMetricRow(r)),
            ],
          ),
        ),
        // Course duel card
        if (duelCourse != null) ...[
          const SizedBox(height: 12),
          _CourseDuelCard(
            c: c,
            body: body,
            label: label,
            course: duelCourse,
            myAvg: _avgScore(myCourses[duelCourse]!),
            theirAvg: _avgScore(friendCourses[duelCourse]!),
            myCount: myCourses[duelCourse]!.length,
            theirCount: friendCourses[duelCourse]!.length,
            friendName: friendName,
          ),
        ],
      ],
    );
  }

  Widget _buildMetricRow(_RivalryMetric m) {
    final total = m.myScore.abs() + m.theirScore.abs();
    final myFrac = total == 0 ? 0.5 : m.myScore.abs() / (total == 0 ? 1 : total);
    final theirFrac = total == 0 ? 0.5 : m.theirScore.abs() / (total == 0 ? 1 : total);

    final myBetter = m.lowerIsBetter
        ? m.myScore < m.theirScore
        : m.myScore > m.theirScore;
    final theirBetter = m.lowerIsBetter
        ? m.theirScore < m.myScore
        : m.theirScore > m.myScore;

    const winColor = Color(0xFF7BE0AD);
    const loseColor = Color(0xFFE2E8F0);
    const textWin = Color(0xFF16A34A);
    const textLose = Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // My value
          SizedBox(
            width: 44,
            child: Text(
              m.myVal,
              style: TextStyle(
                color: myBetter ? textWin : textLose,
                fontSize: label * 1.0,
                fontWeight: myBetter ? FontWeight.w800 : FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          // Bidirectional bar
          Expanded(
            child: Column(
              children: [
                Text(
                  m.label,
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: label * 0.88,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                LayoutBuilder(builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final half = w / 2;
                  final myBarW = myBetter
                      ? half * myFrac.clamp(0.15, 1.0)
                      : half * 0.15;
                  final theirBarW = theirBetter
                      ? half * theirFrac.clamp(0.15, 1.0)
                      : half * 0.15;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // My bar (right-aligned to center)
                      SizedBox(
                        width: (w - 2) / 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: myBarW,
                              height: 7,
                              decoration: BoxDecoration(
                                color: myBetter ? winColor : loseColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Center divider
                      Container(
                          width: 2, height: 14,
                          color: const Color(0xFFCBD5E1)),
                      // Their bar (left-aligned from center)
                      SizedBox(
                        width: (w - 2) / 2,
                        child: Row(
                          children: [
                            Container(
                              width: theirBarW,
                              height: 7,
                              decoration: BoxDecoration(
                                color: theirBetter ? winColor : loseColor,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          // Their value
          SizedBox(
            width: 44,
            child: Text(
              m.theirVal,
              style: TextStyle(
                color: theirBetter ? textWin : textLose,
                fontSize: label * 1.0,
                fontWeight: theirBetter ? FontWeight.w800 : FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _RivalryMetric {
  final String label, myVal, theirVal;
  final double myScore, theirScore;
  final bool lowerIsBetter;
  const _RivalryMetric({
    required this.label,
    required this.myVal,
    required this.theirVal,
    required this.myScore,
    required this.theirScore,
    required this.lowerIsBetter,
  });
}

// ── Course Rivalry Card ────────────────────────────────────────────────────────

class _CourseDuelCard extends StatelessWidget {
  const _CourseDuelCard({
    required this.c,
    required this.body,
    required this.label,
    required this.course,
    required this.myAvg,
    required this.theirAvg,
    required this.myCount,
    required this.theirCount,
    required this.friendName,
  });

  final AppColors c;
  final double body, label;
  final String course, friendName;
  final double myAvg, theirAvg;
  final int myCount, theirCount;

  String _avgStr(double avg) =>
      avg == 0 ? 'E' : avg > 0 ? '+${avg.toStringAsFixed(1)}' : avg.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final iWin = myAvg <= theirAvg;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFAEE5D8), width: 1.2),
        ),
        shadows: [
          BoxShadow(
            color: const Color(0xFF7BE0AD).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFE6FAF3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded,
                    color: Color(0xFF7BE0AD), size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  course,
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: body * 0.95,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: iWin
                      ? const Color(0xFF7BE0AD).withValues(alpha: 0.15)
                      : const Color(0xFFE5D0E3).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: iWin
                        ? const Color(0xFF7BE0AD)
                        : const Color(0xFFE5D0E3),
                    width: 1,
                  ),
                ),
                child: Text(
                  iWin ? '✓ You win' : '$friendName wins',
                  style: TextStyle(
                    color: iWin
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF7C3AED),
                    fontSize: label * 0.9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Avg',
                          style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: label * 0.85)),
                      const SizedBox(height: 3),
                      Text(
                        _avgStr(myAvg),
                        style: TextStyle(
                          color: iWin
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF0F172A),
                          fontSize: body * 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('$myCount rounds',
                          style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: label * 0.82)),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: const Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${friendName.length > 10 ? '${friendName.substring(0, 9)}…' : friendName}\'s Avg',
                          style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: label * 0.85)),
                      const SizedBox(height: 3),
                      Text(
                        _avgStr(theirAvg),
                        style: TextStyle(
                          color: !iWin
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF0F172A),
                          fontSize: body * 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('$theirCount rounds',
                          style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: label * 0.82)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Round row ─────────────────────────────────────────────────────────────────

class _RoundRow extends StatelessWidget {
  const _RoundRow(
      {required this.c,
      required this.body,
      required this.label,
      required this.round});

  final AppColors c;
  final double body, label;
  final Round round;

  @override
  Widget build(BuildContext context) {
    final diff = round.scoreDiff;
    final diffStr =
        diff == 0 ? 'E' : diff > 0 ? '+$diff' : '$diff';
    final diffColor = diff < 0
        ? const Color(0xFF3B82F6)
        : diff == 0
            ? const Color(0xFF16A34A)
            : const Color(0xFF94A3B8);
    final diffBg = diff < 0
        ? const Color(0xFFEFF6FF)
        : diff == 0
            ? const Color(0xFFE6FAF3)
            : const Color(0xFFF1F5F9);

    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final d = (round.completedAt ?? round.startedAt).toLocal();
    final dateStr = '${months[d.month - 1]} ${d.day}, ${d.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE7E5E5)),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Course icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE6FAF3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_golf_rounded,
                color: Color(0xFF7BE0AD), size: 18),
          ),
          const SizedBox(width: 12),
          // Course + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(round.courseName,
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(dateStr,
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Score + diff pill
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${round.totalScore}',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: diffBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  diffStr,
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

// ── Large avatar ──────────────────────────────────────────────────────────────

class _AvatarLg extends StatelessWidget {
  const _AvatarLg({required this.name, this.url});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    final c = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.accentBg,
        shape: BoxShape.circle,
        border: Border.all(color: c.accentBorder, width: 1.5),
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? Image.network(url!, width: size, height: size, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(c, size))
            : _initials(c, size),
      ),
    );
  }

  Widget _initials(AppColors c, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.accentBg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: c.accent,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ── Internal data class ───────────────────────────────────────────────────────

class _DetailData {
  final AppStats friendStats;
  final AppStats myStats;
  final List<Round> recentRounds;
  final List<Round> friendRounds;
  final List<Round> myRounds;

  _DetailData(
      {required this.friendStats,
      required this.myStats,
      required this.recentRounds,
      required this.friendRounds,
      required this.myRounds});
}
