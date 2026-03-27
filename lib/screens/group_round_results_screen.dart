import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:share_plus/share_plus.dart';
import '../models/group_round.dart';
import '../services/group_round_service.dart';
import '../theme/app_theme.dart';

class GroupRoundResultsScreen extends StatelessWidget {
  const GroupRoundResultsScreen({
    super.key,
    required this.sessionId,
    required this.myRoundId,
    required this.courseName,
  });

  final String sessionId;
  final String myRoundId;
  final String courseName;

  @override
  Widget build(BuildContext context) {
    final c     = AppColors.of(context);
    final sw    = MediaQuery.of(context).size.width;
    final sh    = MediaQuery.of(context).size.height;
    final hPad  = (sw * 0.055).clamp(18.0, 28.0);
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final myUid = FirebaseAuth.instance.currentUser!.uid;

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
          child: StreamBuilder<GroupRound>(
            stream: GroupRoundService.sessionStream(sessionId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(
                    child: CircularProgressIndicator(
                        color: c.accent, strokeWidth: 2));
              }
              final session = snap.data!;
              // All players — declined are shown at the bottom
              final allPlayers = session.players.values.toList();
              final activePlayers = allPlayers
                  .where((p) => p.status != 'declined')
                  .toList();
              final allDone =
                  activePlayers.every((p) => p.status == 'completed');

              // Sort: completed by score → still playing → declined at bottom
              final sorted = List<GroupRoundPlayer>.from(allPlayers)
                ..sort((a, b) {
                  final aDeclined = a.status == 'declined';
                  final bDeclined = b.status == 'declined';
                  if (aDeclined && !bDeclined) return 1;
                  if (!aDeclined && bDeclined) return -1;
                  final aScore = a.totalScore;
                  final bScore = b.totalScore;
                  if (aScore == null && bScore == null) return 0;
                  if (aScore == null) return 1;
                  if (bScore == null) return -1;
                  return aScore.compareTo(bScore);
                });

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        hPad, sh * 0.022, hPad, sh * 0.010),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.popUntil(
                              context, (r) => r.isFirst),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.iconContainerBg,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: c.iconContainerBorder),
                            ),
                            child: Icon(Icons.home_rounded,
                                color: c.iconColor, size: body),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                courseName,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: c.primaryText,
                                  fontSize: (sw * 0.050).clamp(17.0, 22.0),
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                allDone
                                    ? 'Final Results'
                                    : 'Waiting for everyone to finish…',
                                style: TextStyle(
                                    color: allDone ? c.accent : c.tertiaryText,
                                    fontSize: label,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        if (allDone)
                          GestureDetector(
                            onTap: () => _share(session),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: ShapeDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF5A9E1F),
                                  Color(0xFF8FD44E)
                                ]),
                                shape: SuperellipseShape(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: const Icon(Icons.share_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Leaderboard
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          hPad, sh * 0.008, hPad, sh * 0.12),
                      itemCount: sorted.length,
                      itemBuilder: (_, i) {
                        final p = sorted[i];
                        final isMe = p.uid == myUid;
                        final done = p.status == 'completed';
                        final declined = p.status == 'declined';

                        // Rank only counts among non-declined players
                        final nonDeclinedIndex = sorted
                            .take(i + 1)
                            .where((x) => x.status != 'declined')
                            .length;
                        final rank = declined ? 0 : nonDeclinedIndex;

                        final medalEmoji = rank == 1 && done
                            ? '🥇'
                            : rank == 2 && done
                                ? '🥈'
                                : rank == 3 && done
                                    ? '🥉'
                                    : null;

                        return Opacity(
                          opacity: declined ? 0.5 : 1.0,
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: ShapeDecoration(
                            color: isMe ? c.accentBg : c.cardBg,
                            shape: SuperellipseShape(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                  color: isMe
                                      ? c.accentBorder
                                      : c.cardBorder),
                            ),
                            shadows: c.cardShadow,
                          ),
                          child: Row(
                            children: [
                              // Rank
                              SizedBox(
                                width: 36,
                                child: declined
                                    ? Icon(Icons.do_not_disturb_rounded,
                                        color: c.tertiaryText, size: 18)
                                    : done
                                        ? (medalEmoji != null
                                            ? Text(medalEmoji,
                                                style: const TextStyle(
                                                    fontSize: 24),
                                                textAlign: TextAlign.center)
                                            : Text('#$rank',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: c.tertiaryText,
                                                    fontSize: label,
                                                    fontWeight:
                                                        FontWeight.w700)))
                                        : Icon(Icons.sports_golf_rounded,
                                            color: c.tertiaryText, size: 20),
                              ),
                              const SizedBox(width: 8),
                              // Avatar
                              _AvatarSm(
                                  url: p.avatarUrl,
                                  name: p.displayName),
                              const SizedBox(width: 10),
                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe ? 'You' : p.displayName,
                                      style: TextStyle(
                                          color: c.primaryText,
                                          fontSize: body,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (declined)
                                      Text('Declined',
                                          style: TextStyle(
                                              color: c.tertiaryText,
                                              fontSize: label))
                                    else if (!done)
                                      Text('Still playing…',
                                          style: TextStyle(
                                              color: c.tertiaryText,
                                              fontSize: label)),
                                  ],
                                ),
                              ),
                              // Score
                              if (done && p.totalScore != null)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${p.totalScore}',
                                      style: TextStyle(
                                          color: c.primaryText,
                                          fontSize: body * 1.1,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      _diffLabel(p.scoreDiff),
                                      style: TextStyle(
                                          color:
                                              _diffColor(c, p.scoreDiff),
                                          fontSize: label,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _diffLabel(double? diff) {
    if (diff == null) return '';
    if (diff == 0) return 'E';
    return diff > 0 ? '+${diff.toInt()}' : '${diff.toInt()}';
  }

  Color _diffColor(AppColors c, double? diff) {
    if (diff == null) return c.tertiaryText;
    if (diff < 0) return const Color(0xFF3B82F6);
    if (diff == 0) return c.accent;
    return c.tertiaryText;
  }

  void _share(GroupRound session) {
    final lines = <String>['⛳ ${session.courseName} — Results\n'];
    final sorted = session.players.values
        .where((p) => p.status == 'completed')
        .toList()
      ..sort((a, b) =>
          (a.totalScore ?? 999).compareTo(b.totalScore ?? 999));
    for (var i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      final medal = i == 0
          ? '🥇'
          : i == 1
              ? '🥈'
              : i == 2
                  ? '🥉'
                  : '  ';
      lines.add(
          '$medal ${p.displayName}: ${p.totalScore} (${_diffLabel(p.scoreDiff)})');
    }
    Share.share(lines.join('\n'));
  }
}

class _AvatarSm extends StatelessWidget {
  const _AvatarSm({required this.name, this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
    final c = AppColors.of(context);
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(url!, width: size, height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials(c)),
      );
    }
    return _initials(c);
  }

  Widget _initials(AppColors c) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: c.accentBg, shape: BoxShape.circle),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: c.accent, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      );
}
