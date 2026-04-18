import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/friend_profile.dart';
import '../models/round.dart';
import '../services/friends_service.dart';
import '../services/stats_service.dart';
import '../services/pressure_score_service.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                            child: Icon(Icons.person_remove_outlined,
                                color: c.tertiaryText, size: 22),
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
                          child: Text('Could not load data',
                              style: TextStyle(color: c.tertiaryText))),
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

                    // Head-to-head
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, 0),
                        child: _HeadToHead(
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
       color: c.accent,
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: ShapeDecoration(
                    color: c.cardBg,
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: c.cardBorder),
                    ),
                    shadows: c.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Icon(t.icon, color: t.color, size: body * 1.1),
                      const SizedBox(height: 4),
                      Text(t.value,
                          style: TextStyle(
                              color: c.primaryText,
                              fontSize: body,
                              fontWeight: FontWeight.w800)),
                      Text(t.lbl,
                          style: TextStyle(
                              color: c.tertiaryText, fontSize: label * 0.9)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Head-to-head ──────────────────────────────────────────────────────────────

class _HeadToHead extends StatelessWidget {
  const _HeadToHead({
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
    // Score badge — count categories where each player wins
    int myWins = 0, theirWins = 0;
    void tally(bool iWin, bool theyWin) {
      if (iWin)    myWins++;
      if (theyWin) theirWins++;
    }
    tally(
      myStats.handicapIndex != null && friendStats.handicapIndex != null &&
          myStats.handicapIndex! < friendStats.handicapIndex!,
      myStats.handicapIndex != null && friendStats.handicapIndex != null &&
          friendStats.handicapIndex! < myStats.handicapIndex!,
    );
    tally(myStats.avgScore < friendStats.avgScore, friendStats.avgScore < myStats.avgScore);
    tally(myStats.totalBirdies > friendStats.totalBirdies, friendStats.totalBirdies > myStats.totalBirdies);
    tally(myStats.girPct > friendStats.girPct, friendStats.girPct > myStats.girPct);
    tally(myStats.avgPutts < friendStats.avgPutts, friendStats.avgPutts < myStats.avgPutts);

    // Pressure scores
    final myPressure     = PressureScoreService.compute(myRounds);
    final friendPressure = PressureScoreService.compute(friendRounds);
    final myPS    = myPressure.compositeScore;
    final themPS  = friendPressure.compositeScore;
    final psIWin    = myRounds.length >= 5 && friendRounds.length >= 5 && myPS > themPS;
    final psTheyWin = myRounds.length >= 5 && friendRounds.length >= 5 && themPS > myPS;
    if (psIWin)    myWins++;
    if (psTheyWin) theirWins++;

    // Course duel — find courses both players have played
    final myCourses     = <String, List<Round>>{};
    final friendCourses = <String, List<Round>>{};
    for (final r in myRounds)     myCourses.putIfAbsent(r.courseName, () => []).add(r);
    for (final r in friendRounds) friendCourses.putIfAbsent(r.courseName, () => []).add(r);
    final sharedCourses = myCourses.keys.where(friendCourses.containsKey).toList();
    // Pick the shared course with most combined rounds
    String? duelCourse;
    if (sharedCourses.isNotEmpty) {
      sharedCourses.sort((a, b) =>
          ((myCourses[b]?.length ?? 0) + (friendCourses[b]?.length ?? 0))
              .compareTo((myCourses[a]?.length ?? 0) + (friendCourses[a]?.length ?? 0)));
      duelCourse = sharedCourses.first;
    }

    double _avg(List<Round> rs) {
      if (rs.isEmpty) return 0;
      return rs.fold(0.0, (s, r) => s + r.scoreDiff) / rs.length;
    }

    final friendShort = friendName.length > 8
        ? '${friendName.substring(0, 7)}…'
        : friendName;

    final rows = [
      _H2HRow(
        stat: 'Handicap',
        mine: myStats.handicapLabel,
        theirs: friendStats.handicapLabel,
        iWin: myStats.handicapIndex != null && friendStats.handicapIndex != null &&
              myStats.handicapIndex! < friendStats.handicapIndex!,
        theyWin: myStats.handicapIndex != null && friendStats.handicapIndex != null &&
                 friendStats.handicapIndex! < myStats.handicapIndex!,
      ),
      _H2HRow(
        stat: 'Avg Score',
        mine: myStats.avgScoreLabel,
        theirs: friendStats.avgScoreLabel,
        iWin: myStats.avgScore < friendStats.avgScore,
        theyWin: friendStats.avgScore < myStats.avgScore,
      ),
      _H2HRow(
        stat: 'Birdies',
        mine: '${myStats.totalBirdies}',
        theirs: '${friendStats.totalBirdies}',
        iWin: myStats.totalBirdies > friendStats.totalBirdies,
        theyWin: friendStats.totalBirdies > myStats.totalBirdies,
      ),
      _H2HRow(
        stat: 'GIR %',
        mine: '${myStats.girPct.toStringAsFixed(0)}%',
        theirs: '${friendStats.girPct.toStringAsFixed(0)}%',
        iWin: myStats.girPct > friendStats.girPct,
        theyWin: friendStats.girPct > myStats.girPct,
      ),
      _H2HRow(
        stat: 'Avg Putts',
        mine: myStats.avgPutts.toStringAsFixed(1),
        theirs: friendStats.avgPutts.toStringAsFixed(1),
        iWin: myStats.avgPutts < friendStats.avgPutts,
        theyWin: friendStats.avgPutts < myStats.avgPutts,
      ),
      _H2HRow(
        stat: 'Pressure',
        mine: myRounds.length >= 5 ? '$myPS' : '--',
        theirs: friendRounds.length >= 5 ? '$themPS' : '--',
        iWin: psIWin,
        theyWin: psTheyWin,
      ),
    ];

    // Score badge text
    String badgeText;
    if (myWins > theirWins) {
      badgeText = 'You lead $myWins–$theirWins';
    } else if (theirWins > myWins) {
      badgeText = '$friendShort leads $theirWins–$myWins';
    } else {
      badgeText = 'Tied $myWins–$theirWins';
    }
    final badgeColor = myWins > theirWins
        ? c.accent
        : theirWins > myWins
            ? c.secondaryText
            : const Color(0xFFFFB74D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: ShapeDecoration(
            color: c.cardBg,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: c.cardBorder),
            ),
            shadows: c.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: label,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Column headers
              Row(
                children: [
                  Expanded(
                    child: Text('You',
                        style: TextStyle(
                            color: c.accent,
                            fontSize: label,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Head to Head',
                        style: TextStyle(
                            color: c.primaryText,
                            fontSize: label,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text(
                        friendShort,
                        style: TextStyle(
                            color: c.secondaryText,
                            fontSize: label,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...rows.map((r) => _buildRow(r)),
            ],
          ),
        ),

        // Course duel card
        if (duelCourse != null) ...[
          const SizedBox(height: 12),
          _buildCourseDuel(context, duelCourse,
              _avg(myCourses[duelCourse]!), _avg(friendCourses[duelCourse]!),
              myCourses[duelCourse]!.length, friendCourses[duelCourse]!.length,
              friendShort),
        ],
      ],
    );
  }

  Widget _buildCourseDuel(BuildContext context, String course,
      double myAvg, double theirAvg, int myCount, int theirCount, String theirName) {
    final iWin = myAvg <= theirAvg;
    final myStr   = myAvg == 0 ? 'E' : myAvg > 0 ? '+${myAvg.toStringAsFixed(1)}' : myAvg.toStringAsFixed(1);
    final theyStr = theirAvg == 0 ? 'E' : theirAvg > 0 ? '+${theirAvg.toStringAsFixed(1)}' : theirAvg.toStringAsFixed(1);

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A3A08).withValues(alpha: 0.85),
            const Color(0xFF3D6E14).withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: [
          BoxShadow(
            color: const Color(0xFF5A9E1F).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: label * 1.1),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  course,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: label,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  iWin ? '✓ You win' : '$theirName wins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: label * 0.9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: label * 0.85)),
                    const SizedBox(height: 2),
                    Text('avg $myStr ($myCount rounds)',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: label,
                            fontWeight: iWin ? FontWeight.w800 : FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(theirName,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: label * 0.85)),
                    const SizedBox(height: 2),
                    Text('avg $theyStr ($theirCount rounds)',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: label,
                            fontWeight: !iWin ? FontWeight.w800 : FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_H2HRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: row.iWin
                  ? BoxDecoration(
                      color: c.accentBg,
                      borderRadius: BorderRadius.circular(8))
                  : null,
              child: Text(row.mine,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: row.iWin ? c.accent : c.secondaryText,
                      fontSize: label,
                      fontWeight:
                          row.iWin ? FontWeight.w800 : FontWeight.w500)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(row.stat,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: c.tertiaryText,
                    fontSize: label * 0.95,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: row.theyWin
                  ? BoxDecoration(
                      color: c.fieldBg,
                      borderRadius: BorderRadius.circular(8))
                  : null,
              child: Text(row.theirs,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: row.theyWin ? c.primaryText : c.secondaryText,
                      fontSize: label,
                      fontWeight: row.theyWin
                          ? FontWeight.w800
                          : FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _H2HRow {
  final String stat, mine, theirs;
  final bool iWin, theyWin;
  const _H2HRow(
      {required this.stat,
      required this.mine,
      required this.theirs,
      required this.iWin,
      required this.theyWin});
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
            ? c.accent
            : c.tertiaryText;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(round.courseName,
                    style: TextStyle(
                        color: c.primaryText,
                        fontSize: body * 0.95,
                        fontWeight: FontWeight.w700)),
                Text(
                  _formatDate(round.completedAt ?? round.startedAt),
                  style: TextStyle(color: c.tertiaryText, fontSize: label),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${round.totalScore}',
                  style: TextStyle(
                      color: c.primaryText,
                      fontSize: body,
                      fontWeight: FontWeight.w800)),
              Text(diffStr,
                  style: TextStyle(
                      color: diffColor,
                      fontSize: label,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final l = d.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[l.month - 1]} ${l.day}, ${l.year}';
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
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(url!, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials(c, size)),
      );
    }
    return _initials(c, size);
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
