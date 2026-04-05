import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/group_round.dart';
import '../services/group_round_service.dart';
import '../theme/app_theme.dart';

// ── Ranked player data class ─────────────────────────────────────────────────

class _RankedPlayer {
  final GroupRoundPlayer player;
  final String rankDisplay; // "1", "T2", "E", etc.
  final int rank;           // numeric rank (for sorting / trend)

  const _RankedPlayer({
    required this.player,
    required this.rankDisplay,
    required this.rank,
  });
}

// ── Tie-aware ranking algorithm ───────────────────────────────────────────────
//
// Rules:
//   1. Only players who have joined or completed are ranked.
//   2. Sort ascending by effectiveScore (liveScore for active, totalScore for
//      completed). Players with no score yet (holesCompleted == 0) go last.
//   3. Equal scores share the same rank and display "T{rank}".
//   4. The next rank after a tie skips appropriately:
//      e.g. two players at T1 → next player is rank 3, not 2.

List<_RankedPlayer> _calculateRanks(Map<String, GroupRoundPlayer> players) {
  final ranked = players.values
      .where((p) => p.status == 'joined' || p.status == 'completed')
      .toList();

  // Effective score: use totalScore for completed, liveScore for active.
  int? _effectiveScore(GroupRoundPlayer p) {
    if (p.status == 'completed') return p.totalScore;
    return p.liveScore;
  }

  ranked.sort((a, b) {
    final sa = _effectiveScore(a);
    final sb = _effectiveScore(b);
    // Players with no score yet go to the bottom
    if (sa == null && sb == null) return a.displayName.compareTo(b.displayName);
    if (sa == null) return 1;
    if (sb == null) return -1;
    if (sa != sb) return sa.compareTo(sb);
    // Tie-break: more holes completed ranks higher (played further)
    if (a.holesCompleted != b.holesCompleted) {
      return b.holesCompleted.compareTo(a.holesCompleted);
    }
    return a.displayName.compareTo(b.displayName);
  });

  final result = <_RankedPlayer>[];
  int position = 1;

  for (int i = 0; i < ranked.length; i++) {
    final player = ranked[i];
    final score  = _effectiveScore(player);

    if (i == 0 || score == null) {
      // First player or no score — assign current position
      final isTied = i + 1 < ranked.length &&
          score != null &&
          _effectiveScore(ranked[i + 1]) == score;
      result.add(_RankedPlayer(
        player: player,
        rank: position,
        rankDisplay: isTied ? 'T$position' : '$position',
      ));
    } else {
      final prevScore = _effectiveScore(ranked[i - 1]);
      if (score == prevScore) {
        // Tie with previous — same rank, prefix T
        result.add(_RankedPlayer(
          player: player,
          rank: result.last.rank,
          rankDisplay: 'T${result.last.rank}',
        ));
        // Retroactively add T to the previous entry if it didn't have it
        if (!result[result.length - 2].rankDisplay.startsWith('T')) {
          final prev = result[result.length - 2];
          result[result.length - 2] = _RankedPlayer(
            player: prev.player,
            rank: prev.rank,
            rankDisplay: 'T${prev.rank}',
          );
        }
      } else {
        // New rank = 1-indexed position in the sorted list
        position = i + 1;
        final isTied = i + 1 < ranked.length &&
            _effectiveScore(ranked[i + 1]) == score;
        result.add(_RankedPlayer(
          player: player,
          rank: position,
          rankDisplay: isTied ? 'T$position' : '$position',
        ));
      }
    }
  }

  // Append invited / declined players without a rank
  for (final p in players.values) {
    if (p.status == 'invited' || p.status == 'declined') {
      result.add(_RankedPlayer(
        player: p,
        rank: 999,
        rankDisplay: '—',
      ));
    }
  }

  return result;
}

// ── Public entry point ────────────────────────────────────────────────────────

/// Shows the live leaderboard as a modal bottom sheet.
/// Listens to [sessionId] in real-time so scores update automatically.
void showLiveLeaderboard(BuildContext context, String sessionId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LiveLeaderboardSheet(sessionId: sessionId),
  );
}

// ── Sheet widget ─────────────────────────────────────────────────────────────

class _LiveLeaderboardSheet extends StatelessWidget {
  final String sessionId;
  const _LiveLeaderboardSheet({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final c  = AppColors.of(context);
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;

    return Container(
      height: sh * 0.72,
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: c.cardBorder)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.of(context).divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: ShapeDecoration(
                    color: c.accentBg,
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: c.accentBorder),
                    ),
                  ),
                  child: Icon(Icons.leaderboard_rounded, color: c.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Leaderboard',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: (sw * 0.048).clamp(16.0, 20.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Updates after each hole',
                      style: TextStyle(color: c.tertiaryText, fontSize: (sw * 0.030).clamp(11.0, 13.0)),
                    ),
                  ],
                ),
                const Spacer(),
                // Live pulse dot
                _PulseDot(color: c.accent),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: c.divider),

          // ── Column headers ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.06, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text('POS', style: _headerStyle(c, sw)),
                ),
                Expanded(child: Text('PLAYER', style: _headerStyle(c, sw))),
                SizedBox(
                  width: 52,
                  child: Text('THRU', style: _headerStyle(c, sw), textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 44,
                  child: Text('SCORE', style: _headerStyle(c, sw), textAlign: TextAlign.end),
                ),
              ],
            ),
          ),

          // ── Live list ────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<GroupRound>(
              stream: GroupRoundService.sessionStream(sessionId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.accent,
                    ),
                  );
                }
                final session = snap.data!;
                final rows    = _calculateRanks(session.players);

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.04,
                    vertical: 4,
                  ),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: sw * 0.04,
                    endIndent: sw * 0.04,
                    color: c.divider.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (_, i) => _LeaderboardRow(
                    ranked: rows[i],
                    totalHoles: session.totalHoles,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(AppColors c, double sw) => TextStyle(
        color: c.tertiaryText,
        fontSize: (sw * 0.027).clamp(10.0, 12.0),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      );
}

// ── Single leaderboard row ───────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final _RankedPlayer ranked;
  final int totalHoles;

  const _LeaderboardRow({required this.ranked, required this.totalHoles});

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final sw  = MediaQuery.of(context).size.width;
    final p   = ranked.player;

    // ── Score display ──────────────────────────────────────────────────────
    final int? effectiveScore = p.status == 'completed'
        ? p.totalScore
        : p.liveScore;

    final String scoreLabel;
    final Color  scoreColor;
    if (effectiveScore == null) {
      scoreLabel = '—';
      scoreColor = c.tertiaryText;
    } else if (effectiveScore == 0) {
      scoreLabel = 'E';
      scoreColor = c.primaryText;
    } else if (effectiveScore < 0) {
      scoreLabel = '$effectiveScore';
      scoreColor = const Color(0xFFE53935); // red = under par (golf convention)
    } else {
      scoreLabel = '+$effectiveScore';
      scoreColor = const Color(0xFF1565C0); // blue = over par
    }

    // ── Through display ────────────────────────────────────────────────────
    final String thruLabel;
    if (p.status == 'completed' || p.holesCompleted == totalHoles) {
      thruLabel = 'F';
    } else if (p.holesCompleted == 0) {
      thruLabel = 'Tee Off';
    } else {
      thruLabel = 'Thru ${p.holesCompleted}';
    }

    // ── Rank badge colours ─────────────────────────────────────────────────
    final bool isTop3  = ranked.rank <= 3 && ranked.rank < 999 && effectiveScore != null;
    final Color rankBg = isTop3
        ? c.accentBg
        : c.scaffoldBg;
    final Color rankFg = isTop3 ? c.accent : c.secondaryText;

    // ── Status indicator for non-active players ───────────────────────────
    final bool isDimmed = p.status == 'declined' || p.status == 'invited';

    return Opacity(
      opacity: isDimmed ? 0.45 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rank badge
            Container(
              width: 36,
              height: 32,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: rankBg,
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(14),
                  side: isTop3 ? BorderSide(color: c.accentBorder) : BorderSide.none,
                ),
              ),
              child: Text(
                ranked.rankDisplay,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: rankFg,
                  fontSize: (sw * 0.032).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Avatar
            _Avatar(player: p, size: (sw * 0.09).clamp(32.0, 40.0)),
            const SizedBox(width: 10),

            // Name + status tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.displayName,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: (sw * 0.036).clamp(13.0, 15.0),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.status == 'invited')
                    Text('Invited', style: TextStyle(color: c.tertiaryText, fontSize: (sw * 0.028).clamp(10.0, 12.0)))
                  else if (p.status == 'declined')
                    Text('Declined', style: TextStyle(color: const Color(0xFFE53935).withValues(alpha: 0.7), fontSize: (sw * 0.028).clamp(10.0, 12.0))),
                ],
              ),
            ),

            // Thru
            SizedBox(
              width: 60,
              child: Text(
                thruLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.tertiaryText,
                  fontSize: (sw * 0.029).clamp(10.0, 12.0),
                ),
              ),
            ),

            // Score
            SizedBox(
              width: 44,
              child: Text(
                scoreLabel,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: scoreColor,
                  fontSize: (sw * 0.040).clamp(14.0, 17.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final GroupRoundPlayer player;
  final double size;
  const _Avatar({required this.player, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final url = player.avatarUrl;
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: c.accentBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(size * 0.4),
          side: BorderSide(color: c.accentBorder),
        ),
        image: url != null && url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: (url == null || url.isEmpty)
          ? Icon(Icons.person_rounded, color: c.accent, size: size * 0.5)
          : null,
    );
  }
}

// ── Pulsing live indicator ────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.4 + 0.6 * _ctrl.value),
        ),
      ),
    );
  }
}
