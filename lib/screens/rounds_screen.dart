import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/round.dart';
import '../services/round_service.dart';
import '../services/group_round_service.dart';
import '../theme/app_theme.dart';
import 'scorecard_import_screen.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/tip_banner.dart';
import '../services/onboarding_service.dart';
import 'scorecard_screen.dart';
import 'round_detail_screen.dart';
import 'practice_screen.dart';
import 'tournament_screen.dart';
import '../utils/l10n_extension.dart';

class RoundsScreen extends StatefulWidget {
  const RoundsScreen({super.key});

  @override
  State<RoundsScreen> createState() => _RoundsScreenState();
}

class _RoundsScreenState extends State<RoundsScreen> {
  int _tab     = 0;
  int _prevTab = 0;

  void _selectTab(int idx) {
    if (idx == _tab) return;
    setState(() {
      _prevTab = _tab;
      _tab     = idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final sw   = MediaQuery.of(context).size.width;
    final sh   = MediaQuery.of(context).size.height;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);
    final body = (sw * 0.036).clamp(13.0, 16.0);
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
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _RoundsHeaderDelegate(
                c: c,
                sw: sw,
                sh: sh,
                hPad: hPad,
                body: body,
                tab: _tab,
                onTabSelected: _selectTab,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                children: [
                  TipBanner(
                    title: context.l10n.roundsHistoryTitle,
                    body: context.l10n.roundsHistorySubtitle,
                    hasSeenFn: OnboardingService.hasSeenRoundsTip,
                    markSeenFn: OnboardingService.markRoundsTipSeen,
                  ),
                  // Active round banner (only in Rounds tab)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: _tab == 0
                        ? StreamBuilder<Round?>(
                            stream: RoundService.activeRoundStream(),
                            builder: (context, snap) {
                              final active = snap.data;
                              if (active == null) return const SizedBox.shrink();
                              return Padding(
                                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.016),
                                child: GestureDetector(
                                  onTap: () async {
                                    String? sessionId = active.sessionId;
                                    if (sessionId == null && active.id != null) {
                                      sessionId = await GroupRoundService.findSessionIdForRound(active.id!);
                                    }
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ScorecardScreen(
                                          roundId: active.id!,
                                          courseName: active.courseName,
                                          totalHoles: active.totalHoles,
                                          initialHole: active.currentHole,
                                          savedScores: active.scores,
                                          lat: active.lat,
                                          lng: active.lng,
                                          sessionId: sessionId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    decoration: ShapeDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1A3A08), Color(0xFF2D5E0E), Color(0xFF7BC344)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: SuperellipseShape(
                                        borderRadius: BorderRadius.circular(48),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            (sw * 0.045).clamp(14.0, 20.0),
                                            sh * 0.016,
                                            (sw * 0.045).clamp(14.0, 20.0),
                                            sh * 0.016,
                                          ),
                                          child: Row(
                                            children: [
                                              _PulsingPlayIcon(color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      context.l10n.roundsInProgress,
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.7),
                                                        fontSize: label,
                                                      ),
                                                    ),
                                                    Text(
                                                      active.courseName,
                                                      style: TextStyle(fontFamily: 'Nunito',
                                                        color: Colors.white,
                                                        fontSize: body,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                context.l10n.roundsHolesProgress(active.holesPlayed, active.totalHoles),
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                  fontSize: label,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(Icons.arrow_forward_ios_rounded,
                                                  color: Colors.white.withValues(alpha: 0.6),
                                                  size: 14),
                                            ],
                                          ),
                                        ),
                                        ClipSuperellipse(
                                          cornerRadius: 20,
                                          child: LinearProgressIndicator(
                                            value: active.totalHoles > 0
                                                ? active.holesPlayed / active.totalHoles
                                                : 0.0,
                                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                                            minHeight: 3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  // AnimatedSwitcher — direct slide to any tab with no intermediate pages
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve:  Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final goingRight = _tab > _prevTab;
                        final isIncoming = (child.key as ValueKey?)?.value == _tab;
                        final inBegin  = goingRight ? const Offset(1, 0) : const Offset(-1, 0);
                        final outBegin = goingRight ? const Offset(-1, 0) : const Offset(1, 0);
                        final begin = isIncoming ? inBegin : outBegin;
                        return SlideTransition(
                          position: Tween<Offset>(begin: begin, end: Offset.zero)
                              .animate(CurvedAnimation(
                                  parent: animation, curve: Curves.easeOutCubic)),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0)
                                .animate(CurvedAnimation(
                                    parent: animation,
                                    curve: const Interval(0.0, 0.6))),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_tab),
                        child: [
                          _buildRoundsList(context, c, sw, sh, hPad, body, label),
                          const PracticeScreen(),
                          const TournamentScreen(),
                        ][_tab],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundsList(BuildContext context, AppColors c, double sw,
      double sh, double hPad, double body, double label) {
    return StreamBuilder<List<Round>>(
      stream: RoundService.allCompletedRoundsStream(),
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final rounds = snap.data ?? [];
        if (!loading && rounds.isEmpty) {
          return _buildEmpty(c, sw, sh, body, label);
        }
        final displayRounds = loading
            ? List.generate(5, (i) => Round(
                userId: '',
                courseName: 'Oak Hills Golf Club',
                courseLocation: 'California, USA',
                totalHoles: 18,
                status: RoundStatus.completed,
                startedAt: DateTime.now(),
              ))
            : rounds;
        return Skeletonizer(
          enabled: loading,
          child: RefreshIndicator(
          onRefresh: () async => await Future.delayed(const Duration(milliseconds: 600)),
          color: const Color(0xFF5A9E1F),
          backgroundColor: Colors.white,
          displacement: 20,
          child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.14),
          itemCount: displayRounds.length,
          separatorBuilder: (_, __) => SizedBox(height: sh * 0.012),
          itemBuilder: (ctx, i) {
            final r = displayRounds[i];
            return Dismissible(
              key: ValueKey(r.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: ctx,
                  builder: (_) => AlertDialog(
                    backgroundColor: c.sheetBg,
                    shape: SuperellipseShape(
                        borderRadius: BorderRadius.circular(40)),
                    title: Text(ctx.l10n.roundsDeleteTitle,
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            color: c.primaryText,
                            fontWeight: FontWeight.w700)),
                    content: Text(
                      ctx.l10n.roundsDeleteConfirm(r.courseName),
                      style: TextStyle(color: c.secondaryText),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(ctx.l10n.cancel,
                              style: TextStyle(color: c.secondaryText))),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(ctx.l10n.delete,
                              style: const TextStyle(color: Color(0xFFFF6B6B)))),
                    ],
                  ),
                );
              },
              onDismissed: (_) => RoundService.deleteRound(r.id!),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(36),
                  ),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFFF6B6B), size: 26),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => RoundDetailScreen(round: r)),
                ),
                child: _RoundCard(round: r, c: c, sw: sw, sh: sh),
              ),
            );
          },
        ),  // ListView.separated
        ),  // RefreshIndicator
        );  // Skeletonizer
      },
    );
  }

  Widget _buildEmpty(AppColors c, double sw, double sh, double body, double label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.golf_course_rounded,
              color: c.tertiaryText,
              size: (sw * 0.16).clamp(54.0, 72.0)),
          SizedBox(height: sh * 0.016),
          Text(
            context.l10n.roundsNoRoundsYet,
            style: TextStyle(
                color: c.secondaryText,
                fontSize: (sw * 0.042).clamp(15.0, 18.0),
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: sh * 0.008),
          Text(
            context.l10n.roundsStartFirst,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: c.tertiaryText,
                fontSize: (sw * 0.034).clamp(12.0, 15.0)),
          ),
          SizedBox(height: sh * 0.018),
          TextButton.icon(
            icon: Icon(Icons.document_scanner_rounded,
                color: c.accent, size: 16),
            label: Text(
              context.l10n.roundsOrScanScorecard,
              style: TextStyle(
                  color: c.accent,
                  fontSize: (sw * 0.034).clamp(12.0, 15.0)),
            ),
            onPressed: () => showScorecardImportFlow(context),
          ),
        ],
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final Round round;
  final AppColors c;
  final double sw;
  final double sh;

  const _RoundCard({
    required this.round,
    required this.c,
    required this.sw,
    required this.sh,
  });

  Color get _diffColor {
    final d = round.scoreDiff;
    if (d < 0)  return const Color(0xFF4CAF82);  // under par
    if (d == 0) return const Color(0xFF64B5F6);  // par
    return const Color(0xFFE53935);              // over par
  }

  String _timeAgo(DateTime dt) {
    final local = dt.toLocal();
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(local.year, local.month, local.day);
    final diff  = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return '${diff}d ago';
    if (diff < 30) return '${(diff / 7).floor()}w ago';
    return '${(diff / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final diff  = round.scoreDiff;
    final diffLabel = diff == 0 ? 'E' : diff > 0 ? '+$diff' : '$diff';

    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(36),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.045).clamp(14.0, 20.0)),
      child: Column(
        children: [
          Row(
            children: [
              // Score badge — matches Practice card icon badge style
              Container(
                width: (sw * 0.12).clamp(40.0, 52.0),
                height: (sw * 0.12).clamp(40.0, 52.0),
                decoration: ShapeDecoration(
                  color: _diffColor.withValues(alpha: 0.12),
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: _diffColor.withValues(alpha: 0.3)),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${round.totalScore}',
                      style: TextStyle(fontFamily: 'Nunito',
                          color: _diffColor,
                          fontSize: (sw * 0.04).clamp(13.0, 17.0),
                          fontWeight: FontWeight.w800,
                          height: 1.0),
                    ),
                    Text(diffLabel,
                        style: TextStyle(color: _diffColor.withValues(alpha: 0.8),
                            fontSize: label * 0.85,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: (sw * 0.035).clamp(10.0, 16.0)),
              // Course info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8FD44E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${round.totalHoles}H',
                              style: TextStyle(
                                  color: const Color(0xFF8FD44E),
                                  fontSize: label * 0.85,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Text(_timeAgo(round.startedAt),
                            style: TextStyle(color: c.tertiaryText, fontSize: label * 0.9)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      round.courseName,
                      style: TextStyle(fontFamily: 'Nunito',
                          color: c.primaryText,
                          fontSize: body,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (round.courseLocation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        round.courseLocation,
                        style: TextStyle(color: c.secondaryText, fontSize: label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.tertiaryText, size: 20),
            ],
          ),
          // Mini stats row
          SizedBox(height: sh * 0.012),
          Divider(color: c.divider, height: 1),
          SizedBox(height: sh * 0.010),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat(c, '${round.birdies}',   context.l10n.roundsBirdies, label, const Color(0xFF8FD44E)),
              _miniStat(c, '${round.pars}',       context.l10n.roundsPars,    label, const Color(0xFF64B5F6)),
              _miniStat(c, '${round.bogeys}',     context.l10n.roundsBogeys,  label, const Color(0xFFFFB74D)),
              _miniStat(c, '${round.totalPutts}', context.l10n.roundsPutts,   label, c.secondaryText),
              _miniStat(c,
                  round.fairwaysHitPct > 0
                      ? '${round.fairwaysHitPct.toStringAsFixed(0)}%'
                      : '-',
                  context.l10n.roundsFIR, label, c.secondaryText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(AppColors c, String value, String label, double fontSize, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontFamily: 'Nunito',
                color: color,
                fontSize: fontSize * 1.05,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(color: c.tertiaryText, fontSize: fontSize * 0.88)),
      ],
    );
  }
}

class _PulsingPlayIcon extends StatefulWidget {
  final Color color;
  const _PulsingPlayIcon({required this.color});
  @override
  State<_PulsingPlayIcon> createState() => _PulsingPlayIconState();
}

class _PulsingPlayIconState extends State<_PulsingPlayIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _scale = Tween(begin: 1.0, end: 1.4).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween(begin: 0.5, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.2),
              border:
                  Border.all(color: widget.color.withValues(alpha: 0.5)),
            ),
            child: Icon(Icons.play_arrow_rounded,
                color: widget.color, size: 22),
          ),
        ],
      ),
    );
  }
}

// ── Sliver header delegate for rounds screen ─────────────────────────────────
class _RoundsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _RoundsHeaderDelegate({
    required this.c,
    required this.sw,
    required this.sh,
    required this.hPad,
    required this.body,
    required this.tab,
    required this.onTabSelected,
  });

  final AppColors c;
  final double sw;
  final double sh;
  final double hPad;
  final double body;
  final int tab;
  final ValueChanged<int> onTabSelected;

  // Title text rendered height: Nunito ascender+descender ≈ fontSize × 1.5
  double get _titleFontSize => (sw * 0.068).clamp(24.0, 30.0);
  double get _titleRowH => sh * 0.022 + _titleFontSize * 1.5 + sh * 0.014;
  // Tab row: container padding(6) + btn vertical padding(16) + text line height + bottom gap
  double get _tabRowH => 6 + 16 + (body * 0.88 * 1.5) + sh * 0.016;

  @override
  double get minExtent => _titleRowH + _tabRowH;
  @override
  double get maxExtent => _titleRowH + _tabRowH;

  Widget _tabBtn(BuildContext context, String title, IconData icon, int idx) {
    final sel = tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: ShapeDecoration(
            gradient: sel
                ? const LinearGradient(
                    colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)],
                  )
                : null,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(48),
            ),
            shadows: sel ? c.cardShadow : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: body * 0.88,
                  color: sel ? c.primaryText : c.tertiaryText,
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: sel ? c.primaryText : c.tertiaryText,
                    fontSize: body * 0.88,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, sh * 0.014),
          child: Text(
            context.l10n.roundsMyRounds,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: _titleFontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.016),
          child: Container(
            decoration: ShapeDecoration(
              color: c.fieldBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: c.fieldBorder),
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _tabBtn(context, context.l10n.roundsRoundsTab,      Icons.golf_course_rounded,  0),
                _tabBtn(context, context.l10n.roundsPracticeTab,    Icons.sports_golf_rounded,  1),
                _tabBtn(context, context.l10n.roundsTournamentsTab, Icons.emoji_events_rounded,  2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(_RoundsHeaderDelegate old) =>
      old.tab != tab || old.c != c;
}
