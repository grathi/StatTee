import 'package:flutter/material.dart';
import '../models/round.dart';
import '../services/round_service.dart';
import '../services/stats_service.dart';
import '../services/strokes_gained_service.dart';
import '../theme/app_theme.dart';

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
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, sh * 0.14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style: TextStyle(fontFamily: 'Nunito',
                            color: c.primaryText,
                            fontSize: (sw * 0.068).clamp(24.0, 30.0),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: sh * 0.024),
                        _buildHandicapCard(c, sw, sh, stats),
                        SizedBox(height: sh * 0.022),
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
        );
      },
    );
  }

  // ── Handicap card ─────────────────────────────────────────────────────────
  Widget _buildHandicapCard(AppColors c, double sw, double sh, AppStats stats) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final hasData = stats.totalRounds > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
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
          const Color(0xFF818CF8)),
      _OverviewItem(
          'Best Round',
          hasData ? '${stats.bestRoundScore}' : '-',
          Icons.emoji_events_rounded,
          const Color(0xFFFFB74D)),
      _OverviewItem('Total Rounds', '${stats.totalRounds}',
          Icons.sports_golf_rounded, const Color(0xFF64B5F6)),
      _OverviewItem('Total Birdies', '${stats.totalBirdies}',
          Icons.flag_rounded, const Color(0xFF34D399)),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      mainAxisExtent: (sh * 0.115).clamp(96.0, 116.0),
      children: items.map((item) => _buildOverviewTile(c, sw, sh, item)).toList(),
    );
  }

  Widget _buildOverviewTile(AppColors c, double sw, double sh, _OverviewItem item) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
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
      _DistItem('Birdies', birdies, total, const Color(0xFF818CF8)),
      _DistItem('Pars', pars, total, const Color(0xFF64B5F6)),
      _DistItem('Bogeys', bogeys, total, const Color(0xFFFFB74D)),
      _DistItem('Double+', doubles, total, const Color(0xFFFF6B6B)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Distribution',
            style: TextStyle(fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: body,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: sh * 0.018),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: items.map((item) {
                final pct = item.count / total;
                if (pct == 0) return const SizedBox.shrink();
                return Expanded(
                  flex: (pct * 1000).round(),
                  child: Container(height: 10, color: item.color),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: sh * 0.016),
          // Legend rows
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: sh * 0.009),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item.label,
                        style:
                            TextStyle(color: c.secondaryText, fontSize: label)),
                    const Spacer(),
                    Text(
                      '${item.count}',
                      style: TextStyle(fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: (sw * 0.02).clamp(6.0, 10.0)),
                    SizedBox(
                      width: (sw * 0.10).clamp(34.0, 44.0),
                      child: Text(
                        '${(item.count / total * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            color: c.tertiaryText, fontSize: label),
                      ),
                    ),
                  ],
                ),
              )),
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

    final diffs = recent.map((r) => r.scoreDiff).toList();
    final maxAbs = diffs.map((d) => d.abs()).reduce((a, b) => a > b ? a : b);
    final range = maxAbs == 0 ? 1 : maxAbs;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
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
            height: (sh * 0.14).clamp(100.0, 130.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recent.asMap().entries.map((e) {
                final diff = e.value.scoreDiff;
                final isUnder = diff <= 0;
                final barColor = isUnder
                    ? const Color(0xFF818CF8)
                    : const Color(0xFFFF6B6B);
                final maxH = (sh * 0.11).clamp(80.0, 108.0);
                final barH = ((diff.abs() / range) * maxH).clamp(4.0, maxH);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          diff == 0
                              ? 'E'
                              : diff > 0
                                  ? '+$diff'
                                  : '$diff',
                          style: TextStyle(
                            color: barColor,
                            fontSize: label * 0.82,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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

  // ── Detailed stats ────────────────────────────────────────────────────────
  Widget _buildDetailedStats(AppColors c, double sw, double sh, AppStats stats) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final hasData = stats.totalRounds > 0;

    final rows = [
      _StatRow('Fairways Hit', hasData ? '${stats.fairwaysHitPct.toStringAsFixed(1)}%' : '-',
          Icons.straighten_rounded, const Color(0xFF34D399)),
      _StatRow('Greens in Regulation', hasData ? '${stats.girPct.toStringAsFixed(1)}%' : '-',
          Icons.flag_rounded, const Color(0xFF64B5F6)),
      _StatRow('Avg Putts / Hole', hasData ? stats.avgPutts.toStringAsFixed(2) : '-',
          Icons.sports_golf_rounded, const Color(0xFFFFB74D)),
      _StatRow('Total Birdies', '${stats.totalBirdies}',
          Icons.emoji_events_rounded, const Color(0xFF818CF8)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
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
                  child: Text(
                    row.label,
                    style: TextStyle(color: c.secondaryText, fontSize: body),
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
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
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
                ? const Color(0xFF818CF8)
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
      _SgItem('Approach', sg.approach, Icons.flag_rounded, const Color(0xFF34D399)),
      _SgItem('Around Green', sg.aroundGreen, Icons.golf_course_rounded, const Color(0xFFFFB74D)),
      _SgItem('Putting', sg.putting, Icons.sports_rounded, const Color(0xFF818CF8)),
    ];
    final maxAbs = categories.map((i) => i.value.abs()).fold(0.0, (a, b) => a > b ? a : b);
    final barScale = maxAbs == 0 ? 1.0 : maxAbs;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
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
                      ? const Color(0xFF34D399).withValues(alpha: 0.15)
                      : const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sg.total >= 0 ? '+' : ''}${sg.total.toStringAsFixed(2)} total',
                  style: TextStyle(
                    color: sg.total >= 0 ? const Color(0xFF34D399) : const Color(0xFFFF6B6B),
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
            final barColor = isPositive ? const Color(0xFF34D399) : const Color(0xFFFF6B6B);
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
                                      color: barColor,
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
                                      color: barColor,
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
}

class _StatRow {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatRow(this.label, this.value, this.icon, this.color);
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
