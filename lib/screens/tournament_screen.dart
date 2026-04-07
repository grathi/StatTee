import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/tournament.dart';
import '../models/round.dart';
import '../services/tournament_service.dart';
import '../services/round_service.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';

class TournamentScreen extends StatelessWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final sw   = MediaQuery.of(context).size.width;
    final sh   = MediaQuery.of(context).size.height;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);

    return Stack(
      children: [
        StreamBuilder<List<Tournament>>(
          stream: TournamentService.tournamentsStream(),
          builder: (context, snap) {
            final tournaments = snap.data ?? [];
            final isLoading =
                snap.connectionState == ConnectionState.waiting && tournaments.isEmpty;

            if (isLoading) {
              return Center(
                  child: CircularProgressIndicator(color: c.accent, strokeWidth: 2));
            }

            if (tournaments.isEmpty) {
              return _buildEmpty(context, c, sw, sh);
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(hPad, sh * 0.010, hPad, sh * 0.12),
              itemCount: tournaments.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: sh * 0.012),
              itemBuilder: (ctx, i) {
                if (i == 0) return _buildWorkflowBanner(context, c, sw, sh);
                return _TournamentCard(
                    tournament: tournaments[i - 1], c: c, sw: sw, sh: sh);
              },
            );
          },
        ),

        // FABs
        Positioned(
          right: (sw * 0.055).clamp(18.0, 28.0),
          bottom: sh * 0.024,
          child: _TournFab(
            icon: Icons.emoji_events_rounded,
            label: context.l10n.tournamentNew,
            color: const Color(0xFF4F46E5),
            onPressed: () => _showCreateSheet(context, c, sw, sh),
            c: c,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowBanner(BuildContext context, AppColors c, double sw, double sh) {
    final label = (sw * 0.030).clamp(11.0, 13.0);
    return Container(
      decoration: ShapeDecoration(
        color: const Color(0xFFFFB74D).withValues(alpha: 0.10),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: const Color(0xFFFFB74D).withValues(alpha: 0.3)),
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.04).clamp(12.0, 18.0),
          vertical: (sh * 0.012).clamp(10.0, 14.0)),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFFFB74D), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.tournamentStartInstructions,
              style: TextStyle(
                  color: const Color(0xFFFFB74D), fontSize: label * 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppColors c, double sw, double sh) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded,
              color: c.tertiaryText, size: (sw * 0.16).clamp(54.0, 72.0)),
          SizedBox(height: sh * 0.016),
          Text(
            context.l10n.tournamentNoTournaments,
            style: TextStyle(
                color: c.secondaryText,
                fontSize: (sw * 0.042).clamp(15.0, 18.0),
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: sh * 0.008),
          Text(
            context.l10n.tournamentCreateInstructions,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: c.tertiaryText,
                fontSize: (sw * 0.034).clamp(12.0, 15.0)),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, AppColors c, double sw, double sh) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateTournamentSheet(c: c, sw: sw, sh: sh),
    );
  }
}

// ── Tournament Card ────────────────────────────────────────────────────────
class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final AppColors c;
  final double sw, sh;

  const _TournamentCard(
      {required this.tournament, required this.c, required this.sw, required this.sh});

  @override
  Widget build(BuildContext context) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    return Dismissible(
      key: ValueKey(tournament.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(context.l10n.tournamentDeleteTitle),
            content: Text(
                context.l10n.tournamentDeleteConfirm(tournament.name)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.cancel)),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.l10n.delete,
                      style: const TextStyle(color: Color(0xFFE53935)))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => TournamentService.deleteTournament(tournament.id!),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: ShapeDecoration(
          color: const Color(0xFFE53935).withValues(alpha: 0.15),
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFE53935), size: 24),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => _TournamentDetailScreen(
                  tournament: tournament, c: c, sw: sw, sh: sh)),
        ),
        child: Container(
          decoration: ShapeDecoration(
            color: c.cardBg,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(36),
              side: BorderSide(color: c.cardBorder),
            ),
            shadows: c.cardShadow,
          ),
          padding: EdgeInsets.all((sw * 0.045).clamp(14.0, 20.0)),
          child: Row(
            children: [
              Container(
                width: (sw * 0.12).clamp(40.0, 52.0),
                height: (sw * 0.12).clamp(40.0, 52.0),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Icon(Icons.emoji_events_rounded,
                    color: const Color(0xFFFFB74D),
                    size: (sw * 0.06).clamp(20.0, 26.0)),
              ),
              SizedBox(width: (sw * 0.035).clamp(10.0, 16.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          color: c.primaryText,
                          fontSize: body,
                          fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${context.l10n.tournamentRoundsCount(tournament.roundIds.length)} · ${_formatDate(tournament.createdAt)}',
                      style: TextStyle(color: c.secondaryText, fontSize: label),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: c.tertiaryText, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
}

// ── Tournament Detail Screen ───────────────────────────────────────────────
class _TournamentDetailScreen extends StatelessWidget {
  final Tournament tournament;
  final AppColors c;
  final double sw, sh;

  const _TournamentDetailScreen(
      {required this.tournament, required this.c, required this.sw, required this.sh});

  @override
  Widget build(BuildContext context) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final hPad  = (sw * 0.055).clamp(18.0, 28.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: c.bgGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Round>>(
            stream: RoundService.tournamentRoundsStream(tournament.id!),
            builder: (context, snap) {
              final rounds = snap.data ?? [];

              int runningTotal = 0;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, sh * 0.022, hPad, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back_rounded,
                                color: c.primaryText, size: 24),
                          ),
                          SizedBox(height: sh * 0.020),
                          Text(
                            tournament.name,
                            style: TextStyle(fontFamily: 'Nunito',
                                color: c.primaryText,
                                fontSize: (sw * 0.068).clamp(24.0, 30.0),
                                fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: sh * 0.022),
                          // Summary tiles
                          Row(
                            children: [
                              _summaryTile(
                                  c, sw, sh,
                                  '${rounds.fold(0, (s, r) => s + r.totalScore)}',
                                  'Total Score', body, label),
                              const SizedBox(width: 10),
                              _summaryTile(
                                  c, sw, sh,
                                  _diffLabel(rounds.fold(
                                      0, (s, r) => s + r.scoreDiff)),
                                  context.l10n.tournamentVsPar, body, label,
                                  color: rounds.fold(
                                              0, (s, r) => s + r.scoreDiff) <=
                                          0
                                      ? const Color(0xFF818CF8)
                                      : const Color(0xFFE53935)),
                              const SizedBox(width: 10),
                              _summaryTile(
                                  c, sw, sh,
                                  '${rounds.length}',
                                  context.l10n.tournamentRoundsLabel, body, label),
                            ],
                          ),
                          SizedBox(height: sh * 0.026),
                          Text(context.l10n.tournamentRoundByRound,
                              style: TextStyle(fontFamily: 'Nunito',
                                  color: c.primaryText,
                                  fontSize: body * 1.1,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: sh * 0.012),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final r = rounds[i];
                        runningTotal += r.scoreDiff;
                        final isLast = i == rounds.length - 1;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 0, hPad,
                              isLast ? sh * 0.1 : sh * 0.010),
                          child: Container(
                            decoration: ShapeDecoration(
                              color: c.cardBg,
                              shape: SuperellipseShape(
                                borderRadius: BorderRadius.circular(32),
                                side: BorderSide(color: c.cardBorder),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: (sw * 0.045).clamp(14.0, 20.0),
                                vertical: (sh * 0.014).clamp(10.0, 16.0)),
                            child: Row(
                              children: [
                                Container(
                                  width: (sw * 0.08).clamp(28.0, 36.0),
                                  height: (sw * 0.08).clamp(28.0, 36.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${i + 1}',
                                        style: TextStyle(
                                            color: const Color(0xFF818CF8),
                                            fontSize: label,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                SizedBox(width: (sw * 0.03).clamp(8.0, 14.0)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.courseName,
                                          style: TextStyle(
                                              color: c.primaryText,
                                              fontSize: label,
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text(
                                        '${r.startedAt.month}/${r.startedAt.day}/${r.startedAt.year}',
                                        style: TextStyle(
                                            color: c.tertiaryText,
                                            fontSize: label * 0.88),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${r.totalScore}',
                                        style: TextStyle(fontFamily: 'Nunito',
                                            color: c.primaryText,
                                            fontSize: body,
                                            fontWeight: FontWeight.w700)),
                                    Text(
                                      _diffLabel(r.scoreDiff),
                                      style: TextStyle(
                                          color: r.scoreDiff < 0
                                              ? const Color(0xFF818CF8)
                                              : r.scoreDiff == 0
                                                  ? c.secondaryText
                                                  : const Color(0xFFE53935),
                                          fontSize: label,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _diffLabel(runningTotal),
                                      style: TextStyle(fontFamily: 'Nunito',
                                          color: runningTotal <= 0
                                              ? const Color(0xFF818CF8)
                                              : const Color(0xFFE53935),
                                          fontSize: label,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text(context.l10n.tournamentRunning,
                                        style: TextStyle(
                                            color: c.tertiaryText,
                                            fontSize: label * 0.8)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: rounds.length,
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

  Widget _summaryTile(AppColors c, double sw, double sh, String value,
      String label, double body, double labelSz, {Color? color}) {
    return Expanded(
      child: Container(
        decoration: ShapeDecoration(
          color: c.cardBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: c.cardBorder),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: sh * 0.016),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontFamily: 'Nunito',
                    color: color ?? c.primaryText,
                    fontSize: (sw * 0.06).clamp(22.0, 28.0),
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(color: c.tertiaryText, fontSize: labelSz * 0.9)),
          ],
        ),
      ),
    );
  }

  String _diffLabel(int diff) =>
      diff == 0 ? 'E' : diff > 0 ? '+$diff' : '$diff';
}

// ── Create Tournament Sheet ────────────────────────────────────────────────
class _CreateTournamentSheet extends StatefulWidget {
  final AppColors c;
  final double sw, sh;

  const _CreateTournamentSheet(
      {required this.c, required this.sw, required this.sh});

  @override
  State<_CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<_CreateTournamentSheet> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  AppColors get c  => widget.c;
  double    get sw => widget.sw;
  double    get sh => widget.sh;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final hPad  = (sw * 0.065).clamp(22.0, 32.0);

    return Container(
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: c.cardBorder),
      ),
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, sh * 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: c.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(context.l10n.tournamentNew,
              style: TextStyle(fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: (sw * 0.052).clamp(18.0, 22.0),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: sh * 0.010),
          Text(
            'Create a tournament, then use "Start Round" to add rounds directly to it.',
            style: TextStyle(color: c.tertiaryText, fontSize: label * 0.95),
          ),
          SizedBox(height: sh * 0.022),

          // Name field
          Text(context.l10n.tournamentNameLabel, style: TextStyle(
              color: c.secondaryText, fontSize: label, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: ShapeDecoration(
              color: c.fieldBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: c.fieldBorder),
              ),
            ),
            child: TextField(
              controller: _nameCtrl,
              style: TextStyle(color: c.primaryText, fontSize: body),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.l10n.tournamentNameHint,
                hintStyle: TextStyle(color: c.tertiaryText, fontSize: body),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          SizedBox(height: sh * 0.028),

          GestureDetector(
            onTap: (_saving || _nameCtrl.text.trim().isEmpty)
                ? null
                : _create,
            child: Opacity(
              opacity: (_saving || _nameCtrl.text.trim().isEmpty) ? 0.5 : 1.0,
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: ShapeDecoration(
                  color: (_saving || _nameCtrl.text.trim().isEmpty)
                      ? c.fieldBg
                      : const Color(0xFF4F46E5),
                  shape: SuperellipseShape(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(context.l10n.tournamentCreate,
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: body,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await TournamentService.createTournament(
          _nameCtrl.text.trim(), []);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Mini FAB with side label ───────────────────────────────────────────────
class _TournFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final AppColors c;

  const _TournFab({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: c.cardBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(40),
                side: BorderSide(color: c.cardBorder),
              ),
              shadows: c.cardShadow,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: onPressed != null ? c.primaryText : c.tertiaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: label,
            onPressed: onPressed,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
