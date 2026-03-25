import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/round.dart';
import '../services/round_service.dart';
import '../services/stats_service.dart';
import '../services/strokes_gained_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_widgets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);

    return StreamBuilder<List<Round>>(
      stream: RoundService.allCompletedRoundsStream(),
      builder: (context, snap) {
        final rounds = snap.data ?? [];
        final stats = StatsService.calculate(rounds);
        final isLoading = snap.connectionState == ConnectionState.waiting;

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
            child: RefreshIndicator(
              onRefresh: () async => await Future.delayed(const Duration(milliseconds: 600)),
              color: const Color(0xFF5A9E1F),
              backgroundColor: Colors.white,
              displacement: 20,
              child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTitleDelegate(
                    title: 'Statistics',
                    topPad: sh * 0.022,
                    hPad: hPad,
                    fontSize: (sw * 0.068).clamp(24.0, 30.0),
                    c: c,
                  ),
                ),
                SliverToBoxAdapter(
                  child: isLoading
                      ? _buildStatsShimmer(context, sw, sh, hPad)
                      : Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: sh * 0.024),
                              _buildHandicapCard(c, sw, sh, stats),
                              SizedBox(height: sh * 0.022),
                              if (rounds.length >= 3) ...[
                                _buildHandicapTrend(context, c, sw, sh, rounds),
                                SizedBox(height: sh * 0.022),
                              ],
                              _buildOverviewGrid(c, sw, sh, stats),
                              SizedBox(height: sh * 0.022),
                              if (rounds.isNotEmpty) ...[
                                _buildScoreDistribution(c, sw, sh, rounds),
                                SizedBox(height: sh * 0.022),
                                _buildScoringTrend(c, sw, sh, rounds),
                                SizedBox(height: sh * 0.022),
                                _buildStrokesGained(c, sw, sh, rounds),
                                SizedBox(height: sh * 0.022),
                                if (_hasClubData(rounds)) ...[
                                  _buildClubStats(c, sw, sh, rounds),
                                  SizedBox(height: sh * 0.022),
                                ],
                              ],
                              _buildDetailedStats(c, sw, sh, stats),
                            ],
                          ),
                        ),
                ),
              ],
            ),  // CustomScrollView
            ),  // RefreshIndicator
          ),    // SafeArea
        );      // Container
      },
    );
  }

  // ── Handicap card ─────────────────────────────────────────────────────────
  Widget _buildStatsShimmer(BuildContext context, double sw, double sh, double hPad) {
    final tileH = (sh * 0.115).clamp(96.0, 116.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: sh * 0.024),
          const ShimmerHandicapCard(),
          SizedBox(height: sh * 0.022),
          ShimmerChartCard(height: (sh * 0.22).clamp(150.0, 220.0)),
          SizedBox(height: sh * 0.022),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: sw * 0.03,
              mainAxisSpacing: sw * 0.03,
              mainAxisExtent: tileH,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => ShimmerOverviewTile(height: tileH),
          ),
          SizedBox(height: sh * 0.022),
          ShimmerChartCard(height: (sh * 0.28).clamp(180.0, 260.0)),
          SizedBox(height: sh * 0.022),
          ShimmerChartCard(height: (sh * 0.18).clamp(130.0, 160.0)),
          SizedBox(height: sh * 0.022),
          ShimmerChartCard(height: (sh * 0.30).clamp(200.0, 300.0)),
        ],
      ),
    );
  }

  Widget _buildHandicapCard(AppColors c, double sw, double sh, AppStats stats) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final hasData = stats.totalRounds > 0;

    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A08), Color(0xFF3D6E14), Color(0xFF5A9E1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
        ),
        shadows: [
          BoxShadow(
            color: const Color(0xFF5A9E1F).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all((sw * 0.06).clamp(20.0, 28.0)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Handicap Index',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: label,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: sh * 0.006),
                Text(
                  hasData ? stats.handicapLabel : '--',
                  style: TextStyle(fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: (sw * 0.18).clamp(58.0, 72.0),
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: sh * 0.008),
                Row(
                  children: [
                    Icon(Icons.golf_course_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: label),
                    const SizedBox(width: 4),
                    Text(
                      hasData
                          ? 'Based on ${stats.totalRounds} round${stats.totalRounds == 1 ? '' : 's'}'
                          : 'Complete rounds to calculate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: label,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Ring chart
          _HandicapRing(handicap: stats.handicapIndex, body: body, label: label),
        ],
      ),
    );
  }

  // ── Overview 2x2 grid ─────────────────────────────────────────────────────
  Widget _buildOverviewGrid(AppColors c, double sw, double sh, AppStats stats) {
    final hasData = stats.totalRounds > 0;
    final items = [
      _OverviewItem('Avg Score', stats.avgScoreLabel, Icons.trending_up_rounded,
          const Color(0xFF8FD44E)),
      _OverviewItem(
          'Best Round',
          hasData ? '${stats.bestRoundScore}' : '-',
          Icons.emoji_events_rounded,
          const Color(0xFFFFB74D)),
      _OverviewItem('Total Rounds', '${stats.totalRounds}',
          Icons.sports_golf_rounded, const Color(0xFF64B5F6)),
      _OverviewItem('Total Birdies', '${stats.totalBirdies}',
          Icons.flag_rounded, const Color(0xFF6DBD35)),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      mainAxisExtent: (sh * 0.115).clamp(96.0, 116.0),
      children: [
        _buildOverviewTile(c, sw, sh, items[0], const Color(0xFF64B5F6)),
        _buildOverviewTile(c, sw, sh, items[1], const Color(0xFF6DBD35)),
        _buildOverviewTile(c, sw, sh, items[2], const Color(0xFF8FD44E)),
        _buildOverviewTile(c, sw, sh, items[3], const Color(0xFFFFD700)),
      ],
    );
  }

  Widget _buildOverviewTile(AppColors c, double sw, double sh, _OverviewItem item, Color tileColor) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    return ClipSuperellipse(
      cornerRadius: 40,
      child: Stack(
        children: [
          Container(
            decoration: ShapeDecoration(
              gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(48),
                side: BorderSide(color: c.cardBorder),
              ),
              shadows: c.cardShadow,
            ),
            padding: EdgeInsets.all((sw * 0.04).clamp(12.0, 16.0)),
            child: Row(
              children: [
                Container(
                  width: (sw * 0.10).clamp(36.0, 44.0),
                  height: (sw * 0.10).clamp(36.0, 44.0),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color,
                      size: (sw * 0.052).clamp(18.0, 22.0)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.value,
                        style: TextStyle(fontFamily: 'Nunito',
                          color: c.primaryText,
                          fontSize: body * 1.25,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        item.label,
                        style: TextStyle(
                            color: c.tertiaryText,
                            fontSize: label * 0.9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Colored left accent bar
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 3,
              color: tileColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Score distribution ────────────────────────────────────────────────────
  Widget _buildScoreDistribution(
      AppColors c, double sw, double sh, List<Round> rounds) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    int eagles = 0, birdies = 0, pars = 0, bogeys = 0, doubles = 0;
    for (final r in rounds) {
      eagles += r.eagles;
      birdies += r.birdies;
      pars += r.pars;
      bogeys += r.bogeys;
      doubles += r.doublePlus;
    }
    final total = eagles + birdies + pars + bogeys + doubles;
    if (total == 0) return const SizedBox.shrink();

    final items = [
      _DistItem('Eagles', eagles, total, const Color(0xFFFFD700)),
      _DistItem('Birdies', birdies, total, const Color(0xFF8FD44E)),
      _DistItem('Pars', pars, total, const Color(0xFF64B5F6)),
      _DistItem('Bogeys', bogeys, total, const Color(0xFFFFB74D)),
      _DistItem('Double+', doubles, total, const Color(0xFFFF6B6B)),
    ];

    // Dominant category (highest count)
    final dominant = items.reduce((a, b) => a.count >= b.count ? a : b);

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Score Distribution',
                  style: TextStyle(fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total holes',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: label * 0.9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.016),

          // ── Stacked proportion bar ───────────────────────────────────────
          ClipSuperellipse(
            cornerRadius: 8,
            child: SizedBox(
              height: 14,
              child: Row(
                children: items
                    .where((i) => i.count > 0)
                    .map((item) => Flexible(
                          flex: item.count,
                          child: Container(color: item.color),
                        ))
                    .toList(),
              ),
            ),
          ),
          SizedBox(height: sh * 0.022),

          // ── Category rows ────────────────────────────────────────────────
          ...items.map((item) {
            final pct = item.pct;
            final isTop = item.label == dominant.label;
            return Padding(
              padding: EdgeInsets.only(bottom: sh * 0.013),
              child: Row(
                children: [
                  // Colored square indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Category label
                  SizedBox(
                    width: (sw * 0.185).clamp(64.0, 80.0),
                    child: Row(
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            color: c.secondaryText,
                            fontSize: label,
                          ),
                        ),
                        if (isTop) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'top',
                              style: TextStyle(
                                color: item.color,
                                fontSize: label * 0.75,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Fill bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            color: item.color.withValues(alpha: 0.12),
                          ),
                          FractionallySizedBox(
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Count
                  SizedBox(
                    width: (sw * 0.06).clamp(22.0, 28.0),
                    child: Text(
                      '${item.count}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Percentage
                  SizedBox(
                    width: (sw * 0.10).clamp(36.0, 44.0),
                    child: Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: c.tertiaryText,
                        fontSize: label * 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Scoring trend (last 10) ───────────────────────────────────────────────
  Widget _buildScoringTrend(
      AppColors c, double sw, double sh, List<Round> rounds) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final recent = rounds.take(10).toList().reversed.toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score vs Par (Last ${recent.length} Rounds)',
            style: TextStyle(fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: body,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: sh * 0.022),
          SizedBox(
            height: (sh * 0.15).clamp(100.0, 130.0),
            child: CustomPaint(
              size: Size(double.infinity, (sh * 0.15).clamp(100.0, 130.0)),
              painter: _ScoreTrendBarPainter(
                rounds: recent,
                positiveColor: const Color(0xFFFF6B6B),
                negativeColor: const Color(0xFF8FD44E),
                gridColor: c.divider,
                labelColor: c.secondaryText,
              ),
            ),
          ),
          SizedBox(height: sh * 0.008),
          Center(
            child: Text(
              'Oldest → Most Recent',
              style:
                  TextStyle(color: c.tertiaryText, fontSize: label * 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── Handicap Trend chart ──────────────────────────────────────────────────
  Widget _buildHandicapTrend(BuildContext context, AppColors c, double sw, double sh, List<Round> rounds) {
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final body  = (sw * 0.036).clamp(13.0, 16.0);

    // Take last 20 rounds, oldest → newest
    final data = rounds.reversed
        .take(20)
        .map((r) => r.scoreDifferential)
        .toList();

    return StreamBuilder<double?>(
      stream: UserProfileService.handicapGoalStream(),
      builder: (ctx, goalSnap) {
        final goal = goalSnap.data;
        return Container(
          decoration: ShapeDecoration(
            gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(48),
              side: BorderSide(color: c.cardBorder),
            ),
            shadows: c.cardShadow,
          ),
          padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Handicap Trend',
                    style: TextStyle(fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: body,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (goal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFB74D).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Goal: $goal',
                        style: TextStyle(
                            color: const Color(0xFFFFB74D),
                            fontSize: label,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              SizedBox(height: sh * 0.018),
              SizedBox(
                height: sh * 0.22,
                child: CustomPaint(
                  painter: _HandicapTrendPainter(
                    data: data,
                    goal: goal,
                    lineColor: c.accent,
                    gridColor: c.divider,
                    textColor: c.secondaryText,
                  ),
                  size: Size.infinite,
                ),
              ),
              SizedBox(height: sh * 0.008),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${data.length} rounds',
                    style: TextStyle(color: c.tertiaryText, fontSize: label * 0.9),
                  ),
                  Text(
                    'Latest: ${data.last.toStringAsFixed(1)}',
                    style: TextStyle(
                        color: c.accent,
                        fontSize: label,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Detailed stats ────────────────────────────────────────────────────────
  Widget _buildDetailedStats(AppColors c, double sw, double sh, AppStats stats) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final hasData = stats.totalRounds > 0;

    final rows = [
      _StatRow('Fairways Hit', hasData ? '${stats.fairwaysHitPct.toStringAsFixed(1)}%' : '-',
          Icons.straighten_rounded, const Color(0xFF6DBD35),
          pctValue: hasData ? stats.fairwaysHitPct : null),
      _StatRow('Greens in Regulation', hasData ? '${stats.girPct.toStringAsFixed(1)}%' : '-',
          Icons.flag_rounded, const Color(0xFF64B5F6),
          pctValue: hasData ? stats.girPct : null),
      _StatRow('Avg Putts / Hole', hasData ? stats.avgPutts.toStringAsFixed(2) : '-',
          Icons.sports_golf_rounded, const Color(0xFFFFB74D)),
      _StatRow('Total Birdies', '${stats.totalBirdies}',
          Icons.emoji_events_rounded, const Color(0xFF8FD44E)),
    ];

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final row = e.value;
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: (sw * 0.05).clamp(16.0, 22.0),
              vertical: (sh * 0.016).clamp(12.0, 18.0),
            ),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: c.divider)),
            ),
            child: Row(
              children: [
                Container(
                  width: (sw * 0.088).clamp(30.0, 38.0),
                  height: (sw * 0.088).clamp(30.0, 38.0),
                  decoration: BoxDecoration(
                    color: row.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(row.icon, color: row.color,
                      size: (sw * 0.044).clamp(15.0, 20.0)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        row.label,
                        style: TextStyle(color: c.secondaryText, fontSize: body),
                      ),
                      if (row.pctValue != null)
                        Container(
                          height: 3,
                          margin: const EdgeInsets.only(top: 3),
                          child: LayoutBuilder(builder: (_, box) => Stack(children: [
                            Container(decoration: BoxDecoration(
                              color: row.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2))),
                            Container(
                              width: box.maxWidth * (row.pctValue! / 100).clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                color: row.color,
                                borderRadius: BorderRadius.circular(2))),
                          ])),
                        ),
                    ],
                  ),
                ),
                Text(
                  row.value,
                  style: TextStyle(fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  bool _hasClubData(List<Round> rounds) =>
      rounds.any((r) => r.scores.any((h) => h.club != null));

  // ── Club Distance Tracker ─────────────────────────────────────────────────
  Widget _buildClubStats(AppColors c, double sw, double sh, List<Round> rounds) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    // Aggregate per club
    final Map<String, _ClubAgg> agg = {};
    for (final r in rounds) {
      for (final h in r.scores) {
        if (h.club == null) continue;
        final a = agg.putIfAbsent(h.club!, () => _ClubAgg());
        a.holes++;
        a.totalDiff += h.score - h.par;
        a.totalPutts += h.putts;
      }
    }
    if (agg.isEmpty) return const SizedBox.shrink();

    // Sort by most used
    final sorted = agg.entries.toList()
      ..sort((a, b) => b.value.holes.compareTo(a.value.holes));

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Club Stats',
            style: TextStyle(fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: body,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: sh * 0.006),
          Text(
            'Score vs par & avg putts per club',
            style: TextStyle(color: c.tertiaryText, fontSize: label * 0.88),
          ),
          SizedBox(height: sh * 0.016),
          // Header
          Row(children: [
            SizedBox(width: (sw * 0.22).clamp(72.0, 90.0),
                child: Text('Club', style: TextStyle(color: c.tertiaryText, fontSize: label * 0.88))),
            Expanded(child: Text('Holes', textAlign: TextAlign.center,
                style: TextStyle(color: c.tertiaryText, fontSize: label * 0.88))),
            Expanded(child: Text('Avg ±Par', textAlign: TextAlign.center,
                style: TextStyle(color: c.tertiaryText, fontSize: label * 0.88))),
            Expanded(child: Text('Avg Putts', textAlign: TextAlign.center,
                style: TextStyle(color: c.tertiaryText, fontSize: label * 0.88))),
          ]),
          Divider(color: c.divider, height: sh * 0.02),
          ...sorted.map((e) {
            final a = e.value;
            final avgDiff = a.totalDiff / a.holes;
            final avgPutts = a.totalPutts / a.holes;
            final diffColor = avgDiff < -0.1
                ? const Color(0xFF8FD44E)
                : avgDiff < 0.1
                    ? const Color(0xFF64B5F6)
                    : avgDiff < 1.0
                        ? const Color(0xFFFFB74D)
                        : const Color(0xFFFF6B6B);
            return Padding(
              padding: EdgeInsets.only(bottom: sh * 0.010),
              child: Row(children: [
                SizedBox(
                  width: (sw * 0.22).clamp(72.0, 90.0),
                  child: Text(e.key,
                      style: TextStyle(fontFamily: 'Nunito',
                          color: c.primaryText,
                          fontSize: label,
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Text('${a.holes}', textAlign: TextAlign.center,
                    style: TextStyle(color: c.secondaryText, fontSize: label))),
                Expanded(child: Text(
                  '${avgDiff >= 0 ? '+' : ''}${avgDiff.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Nunito',
                      color: diffColor,
                      fontSize: label,
                      fontWeight: FontWeight.w700),
                )),
                Expanded(child: Text(
                  avgPutts.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.secondaryText, fontSize: label),
                )),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // ── Strokes Gained ────────────────────────────────────────────────────────
  Widget _buildStrokesGained(AppColors c, double sw, double sh, List<Round> rounds) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final sg = StrokesGainedService.calculate(rounds);

    final categories = [
      _SgItem('Off the Tee', sg.offTee, Icons.sports_golf_rounded, const Color(0xFF64B5F6)),
      _SgItem('Approach', sg.approach, Icons.flag_rounded, const Color(0xFF6DBD35)),
      _SgItem('Around Green', sg.aroundGreen, Icons.golf_course_rounded, const Color(0xFFFFB74D)),
      _SgItem('Putting', sg.putting, Icons.sports_rounded, const Color(0xFF8FD44E)),
    ];
    final maxAbs = categories.map((i) => i.value.abs()).fold(0.0, (a, b) => a > b ? a : b);
    final barScale = maxAbs == 0 ? 1.0 : maxAbs;

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Strokes Gained',
                  style: TextStyle(fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sg.total >= 0
                      ? const Color(0xFF6DBD35).withValues(alpha: 0.15)
                      : const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sg.total >= 0 ? '+' : ''}${sg.total.toStringAsFixed(2)} total',
                  style: TextStyle(
                    color: sg.total >= 0 ? const Color(0xFF6DBD35) : const Color(0xFFFF6B6B),
                    fontSize: label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.006),
          Text(
            'vs scratch golfer baseline',
            style: TextStyle(color: c.tertiaryText, fontSize: label * 0.88),
          ),
          SizedBox(height: sh * 0.018),
          ...categories.map((item) {
            final isPositive = item.value >= 0;
            final barColor = isPositive ? const Color(0xFF6DBD35) : const Color(0xFFFF6B6B);
            final barFraction = (item.value.abs() / barScale).clamp(0.0, 1.0);
            final maxBarWidth = sw * 0.38;

            return Padding(
              padding: EdgeInsets.only(bottom: sh * 0.014),
              child: Row(
                children: [
                  Container(
                    width: (sw * 0.078).clamp(28.0, 34.0),
                    height: (sw * 0.078).clamp(28.0, 34.0),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(item.icon, color: item.color,
                        size: (sw * 0.038).clamp(13.0, 17.0)),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: (sw * 0.26).clamp(90.0, 120.0),
                    child: Text(
                      item.label,
                      style: TextStyle(color: c.secondaryText, fontSize: label),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // Negative bar (left of center)
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: isPositive
                                ? const SizedBox.shrink()
                                : AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    width: barFraction * maxBarWidth * 0.5,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF6B6B), Color(0xFFFF4040)],
                                        begin: Alignment.centerRight,
                                        end: Alignment.centerLeft,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        // Centre line
                        Container(
                          width: 1.5,
                          height: 16,
                          color: c.divider,
                        ),
                        // Positive bar (right of center)
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: isPositive
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    width: barFraction * maxBarWidth * 0.5,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6DBD35), Color(0xFF59A020)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(4),
                                        bottomRight: Radius.circular(4),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: (sw * 0.12).clamp(42.0, 52.0),
                    child: Text(
                      '${isPositive ? '+' : ''}${item.value.toStringAsFixed(2)}',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontFamily: 'Nunito',
                        color: barColor,
                        fontSize: label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Ring widget ───────────────────────────────────────────────────────────────
class _HandicapRing extends StatelessWidget {
  final double handicap;
  final double body;
  final double label;

  const _HandicapRing(
      {required this.handicap, required this.body, required this.label});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final size = (sw * 0.22).clamp(72.0, 88.0);
    final progress = (1 - (handicap / 54)).clamp(0.0, 1.0);
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
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: body * 0.9,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                'Better\nthan avg',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: label * 0.82,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────
class _OverviewItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _OverviewItem(this.label, this.value, this.icon, this.color);
}

class _DistItem {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _DistItem(this.label, this.count, this.total, this.color);
  double get pct => total == 0 ? 0.0 : count / total;
}

class _StatRow {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? pctValue;
  const _StatRow(this.label, this.value, this.icon, this.color, {this.pctValue});
}

class _SgItem {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  const _SgItem(this.label, this.value, this.icon, this.color);
}

class _ClubAgg {
  int holes = 0;
  int totalDiff = 0;
  int totalPutts = 0;
}

class _ScoreTrendBarPainter extends CustomPainter {
  final List<Round> rounds;
  final Color positiveColor;
  final Color negativeColor;
  final Color gridColor;
  final Color labelColor;

  const _ScoreTrendBarPainter({
    required this.rounds,
    required this.positiveColor,
    required this.negativeColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rounds.isEmpty) return;
    final n = rounds.length;
    final barW = (size.width / n) * 0.55;
    final gap = (size.width / n) * 0.45;
    final midY = size.height * 0.55;

    // Par baseline
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY),
        Paint()..color = gridColor..strokeWidth = 1.0);

    final maxAbs = rounds.map((r) => r.scoreDiff.abs())
        .fold(1, math.max).toDouble();

    for (var i = 0; i < n; i++) {
      final round = rounds[i];
      final diff = round.scoreDiff;
      final frac = (diff.abs() / maxAbs).clamp(0.0, 1.0);
      final barH = (midY * 0.8) * frac;
      final x = i * (size.width / n) + gap / 2;
      final isOver = diff > 0;
      final color = isOver ? positiveColor : negativeColor;

      if (barH < 1.0) continue;

      final rect = RRect.fromRectAndRadius(
        isOver
            ? Rect.fromLTWH(x, midY + 2, barW, barH)
            : Rect.fromLTWH(x, midY - barH - 2, barW, barH),
        const Radius.circular(3),
      );

      // Glow on most recent
      if (i == n - 1) {
        canvas.drawRRect(rect.inflate(2),
            Paint()..color = color.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      }

      canvas.drawRRect(rect,
          Paint()..shader = LinearGradient(
            colors: isOver
                ? [const Color(0xFFFF6B6B), const Color(0xFFFF4040)]
                : [const Color(0xFF8FD44E), const Color(0xFF5A9E1F)],
            begin: isOver ? Alignment.topCenter : Alignment.bottomCenter,
            end: isOver ? Alignment.bottomCenter : Alignment.topCenter,
          ).createShader(rect.outerRect));

      // Label
      if (diff != 0) {
        final lp = TextPainter(
          text: TextSpan(
            text: diff > 0 ? '+$diff' : '$diff',
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        lp.paint(canvas, Offset(
          x + barW / 2 - lp.width / 2,
          isOver ? midY + barH + 4 : midY - barH - lp.height - 4,
        ));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _HandicapTrendPainter extends CustomPainter {
  final List<double> data;
  final double? goal;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  const _HandicapTrendPainter({
    required this.data,
    this.goal,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final allValues = [...data, if (goal != null) goal!];
    final minVal = allValues.reduce((a, b) => a < b ? a : b) - 1.0;
    final maxVal = allValues.reduce((a, b) => a > b ? a : b) + 1.0;
    final range = maxVal - minVal;

    double toY(double v) =>
        size.height * (1 - (v - minVal) / range);
    double toX(int i) =>
        size.width * i / (data.length - 1);

    // Y-axis labels (left edge): max, mid, min
    final yLabelValues = [maxVal, (maxVal + minVal) / 2, minVal];
    for (final v in yLabelValues) {
      final tp = TextPainter(
        text: TextSpan(
          text: v.toStringAsFixed(1),
          style: TextStyle(color: textColor, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, toY(v) - tp.height / 2));
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Goal line (amber dashed)
    if (goal != null) {
      final goalY = toY(goal!);
      final goalPaint = Paint()
        ..color = const Color(0xFFFFB74D)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      const dash = 8.0;
      const gap = 5.0;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, goalY),
          Offset((x + dash).clamp(0.0, size.width), goalY),
          goalPaint,
        );
        x += dash + gap;
      }
    }

    // Polyline with smooth cubic bezier
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = toX(i);
      final y = toY(data[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = toX(i - 1);
        final prevY = toY(data[i - 1]);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    // Gradient area fill under the line
    final lastX = toX(data.length - 1);
    final fillPath = Path()..addPath(path, Offset.zero);
    fillPath.lineTo(lastX, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withValues(alpha: 0.22),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Find best (min) and worst (max) indices
    int bestIdx = 0, worstIdx = 0;
    for (int i = 1; i < data.length; i++) {
      if (data[i] < data[bestIdx]) bestIdx = i;
      if (data[i] > data[worstIdx]) worstIdx = i;
    }

    // Dots
    final dotPaint = Paint()..color = lineColor;
    final dotOutline = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < data.length; i++) {
      final x = toX(i);
      final y = toY(data[i]);
      if (i == bestIdx) {
        canvas.drawCircle(Offset(x, y), 5.5, Paint()..color = const Color(0xFFFFD700));
      } else if (i == worstIdx) {
        canvas.drawCircle(Offset(x, y), 5.5,
            Paint()..color = const Color(0xFFFF6B6B).withValues(alpha: 0.8));
      } else {
        final r = i == data.length - 1 ? 5.0 : 3.0;
        canvas.drawCircle(Offset(x, y), r, dotPaint);
        if (i == data.length - 1) {
          canvas.drawCircle(Offset(x, y), r, dotOutline);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HandicapTrendPainter old) =>
      old.data != data || old.goal != goal;
}

// ── Sticky title delegate ─────────────────────────────────────────────────────

class _StickyTitleDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTitleDelegate({
    required this.title,
    required this.topPad,
    required this.hPad,
    required this.fontSize,
    required this.c,
  });

  final String title;
  final double topPad;
  final double hPad;
  final double fontSize;
  final AppColors c;

  double get _extent => topPad + fontSize * 1.6 + 14;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: c.bgGradient.take(2).toList(),
          stops: const [0.0, 1.0],
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 14),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Nunito',
          color: c.primaryText,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTitleDelegate old) =>
      old.title != title || old.c != c;
}
