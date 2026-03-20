import 'package:flutter/material.dart';
import '../models/round.dart';
import '../services/round_service.dart';
import '../theme/app_theme.dart';
import 'scorecard_screen.dart';
import 'round_detail_screen.dart';

class RoundsScreen extends StatelessWidget {
  const RoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
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
              padding: EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, sh * 0.018),
              child: Text(
                'My Rounds',
                style: TextStyle(fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: (sw * 0.068).clamp(24.0, 30.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Active round banner
            StreamBuilder<Round?>(
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
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: (sw * 0.045).clamp(14.0, 20.0),
                          vertical: sh * 0.016),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 20),
                          ),
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
                  ),
                );
              },
            ),
            // Completed rounds list
            Expanded(
              child: StreamBuilder<List<Round>>(
                stream: RoundService.allCompletedRoundsStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: c.accent,
                        strokeWidth: 2,
                      ),
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
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: Text('Cancel',
                                        style: TextStyle(
                                            color: c.secondaryText))),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color: Color(0xFFFF6B6B)))),
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
              ),
            ),
          ],
        ),
      ),
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
    if (d < 0) return const Color(0xFF818CF8);
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
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.cardBorder),
        boxShadow: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.045).clamp(14.0, 20.0)),
      child: Column(
        children: [
          Row(
            children: [
              // Score circle
              Container(
                width: (sw * 0.13).clamp(46.0, 56.0),
                height: (sw * 0.13).clamp(46.0, 56.0),
                decoration: BoxDecoration(
                  color: _diffColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _diffColor.withValues(alpha: 0.3)),
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
                  const Color(0xFF818CF8)),
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
