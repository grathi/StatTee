import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/round.dart';
import '../services/round_service.dart';
import '../theme/app_theme.dart';
import 'scorecard_screen.dart';
import 'round_detail_screen.dart';
import 'practice_screen.dart';
import 'tournament_screen.dart';

class RoundsScreen extends StatefulWidget {
  const RoundsScreen({super.key});

  @override
  State<RoundsScreen> createState() => _RoundsScreenState();
}

class _RoundsScreenState extends State<RoundsScreen> {
  int _tab = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _selectTab(int idx) {
    if (idx == _tab) return;
    setState(() => _tab = idx);
    _pageCtrl.animateToPage(
      idx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, sh * 0.014),
              child: Text(
                'My Rounds',
                style: TextStyle(fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: (sw * 0.068).clamp(24.0, 30.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Segmented control
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.016),
              child: Container(
                decoration: BoxDecoration(
                  color: c.fieldBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.fieldBorder),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _tabBtn('Rounds',      0, c, body),
                    _tabBtn('Practice',    1, c, body),
                    _tabBtn('Tournaments', 2, c, body),
                  ],
                ),
              ),
            ),
            // Active round banner (only in Rounds tab, fades out on other tabs)
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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ScorecardScreen(
                                  roundId: active.id!,
                                  courseName: active.courseName,
                                  totalHoles: active.totalHoles,
                                ),
                              ),
                            ),
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
                                                'Round in Progress',
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
                                          '${active.holesPlayed}/${active.totalHoles} holes',
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
            // PageView — smooth slide between tabs
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _tab = i),
                children: [
                  _buildRoundsList(context, c, sw, sh, hPad, body, label),
                  const PracticeScreen(),
                  const TournamentScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String title, int idx, AppColors c, double body) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8),
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
            child: Text(
              title,
              style: TextStyle(
                color: sel ? c.primaryText : c.tertiaryText,
                fontSize: body * 0.88,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundsList(BuildContext context, AppColors c, double sw,
      double sh, double hPad, double body, double label) {
    return StreamBuilder<List<Round>>(
      stream: RoundService.allCompletedRoundsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: c.accent, strokeWidth: 2),
          );
        }
        final rounds = snap.data ?? [];
        if (rounds.isEmpty) {
          return _buildEmpty(c, sw, sh, body, label);
        }
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sh * 0.14),
          itemCount: rounds.length,
          separatorBuilder: (_, __) => SizedBox(height: sh * 0.012),
          itemBuilder: (ctx, i) {
            final r = rounds[i];
            return Dismissible(
              key: ValueKey(r.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: ctx,
                  builder: (_) => AlertDialog(
                    backgroundColor: c.sheetBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text('Delete Round?',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            color: c.primaryText,
                            fontWeight: FontWeight.w700)),
                    content: Text(
                      'Permanently remove your round at ${r.courseName}?',
                      style: TextStyle(color: c.secondaryText),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel',
                              style: TextStyle(color: c.secondaryText))),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Color(0xFFFF6B6B)))),
                    ],
                  ),
                );
              },
              onDismissed: (_) => RoundService.deleteRound(r.id!),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
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
        );
      },
    );
  }

  Widget _buildEmpty(AppColors c, double sw, double sh, double body, double label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: (sw * 0.22).clamp(72.0, 88.0),
            height: (sw * 0.22).clamp(72.0, 88.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.iconContainerBg,
              border: Border.all(color: c.iconContainerBorder),
            ),
            child: Icon(Icons.golf_course_rounded,
                color: c.tertiaryText,
                size: (sw * 0.10).clamp(34.0, 42.0)),
          ),
          SizedBox(height: sh * 0.022),
          Text(
            'No rounds yet',
            style: TextStyle(fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: body * 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: sh * 0.006),
          Text(
            'Start your first round from the Home tab',
            style: TextStyle(color: c.tertiaryText, fontSize: label),
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
    if (d < 0) return const Color(0xFF8FD44E);
    if (d == 0) return const Color(0xFF64B5F6);
    return const Color(0xFFFF6B6B);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(colors: c.cardGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.045).clamp(14.0, 20.0)),
      child: Column(
        children: [
          Row(
            children: [
              // Score circle
              CustomPaint(
                painter: _ScoreCircleArcPainter(
                  scoreDiff: round.scoreDiff,
                  arcColor: _diffColor,
                  trackColor: c.cardBorder,
                ),
                child: Container(
                  width: (sw * 0.13).clamp(46.0, 56.0),
                  height: (sw * 0.13).clamp(46.0, 56.0),
                  decoration: BoxDecoration(
                    color: _diffColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${round.totalScore}',
                        style: TextStyle(fontFamily: 'Nunito',
                          color: _diffColor,
                          fontSize: (sw * 0.046).clamp(15.0, 20.0),
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        round.scoreDiffLabel,
                        style: TextStyle(
                          color: _diffColor.withValues(alpha: 0.8),
                          fontSize: label * 0.85,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Course info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      round.courseName,
                      style: TextStyle(fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: body,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (round.courseLocation.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: c.tertiaryText, size: label),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              round.courseLocation,
                              style: TextStyle(
                                  color: c.tertiaryText, fontSize: label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Date + holes
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _timeAgo(round.startedAt),
                    style: TextStyle(
                        color: c.tertiaryText, fontSize: label),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.iconContainerBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${round.totalHoles}H',
                      style: TextStyle(
                        color: c.secondaryText,
                        fontSize: label,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Mini stats row
          SizedBox(height: sh * 0.012),
          Divider(color: c.divider, height: 1),
          SizedBox(height: sh * 0.010),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat(c, '${round.birdies}', 'Birdies', label,
                  const Color(0xFF8FD44E)),
              _miniStat(c, '${round.pars}', 'Pars', label,
                  const Color(0xFF64B5F6)),
              _miniStat(c, '${round.bogeys}', 'Bogeys', label,
                  const Color(0xFFFFB74D)),
              _miniStat(c, '${round.totalPutts}', 'Putts', label,
                  c.secondaryText),
              _miniStat(
                  c,
                  round.fairwaysHitPct > 0
                      ? '${round.fairwaysHitPct.toStringAsFixed(0)}%'
                      : '-',
                  'FIR',
                  label,
                  c.secondaryText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(AppColors c, String value, String label, double fontSize,
      Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontFamily: 'Nunito',
            color: color,
            fontSize: fontSize * 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label,
            style: TextStyle(color: c.tertiaryText, fontSize: fontSize * 0.88)),
      ],
    );
  }
}

class _ScoreCircleArcPainter extends CustomPainter {
  final int scoreDiff;
  final Color arcColor;
  final Color trackColor;
  const _ScoreCircleArcPainter({
    required this.scoreDiff,
    required this.arcColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = 2.45;
    const sweepAngle = 5.38; // ~308°

    // Track
    canvas.drawArc(rect, startAngle, sweepAngle, false,
        Paint()
          ..color = trackColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Fill based on diff: neutral=50%, better=more, worse=less
    final fillFrac = scoreDiff <= 0
        ? (0.5 + (-scoreDiff * 0.12)).clamp(0.0, 1.0)
        : (0.5 - (scoreDiff * 0.10)).clamp(0.05, 0.5);

    canvas.drawArc(rect, startAngle, sweepAngle * fillFrac, false,
        Paint()
          ..color = arcColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Bloom dot at end
    final endAngle = startAngle + sweepAngle * fillFrac;
    final dotX = center.dx + radius * math.cos(endAngle);
    final dotY = center.dy + radius * math.sin(endAngle);
    canvas.drawCircle(Offset(dotX, dotY), 3.5,
        Paint()..color = arcColor.withValues(alpha: 0.35));
    canvas.drawCircle(Offset(dotX, dotY), 2.0, Paint()..color = arcColor);
  }

  @override
  bool shouldRepaint(covariant _ScoreCircleArcPainter old) =>
      old.scoreDiff != scoreDiff || old.arcColor != arcColor;
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
