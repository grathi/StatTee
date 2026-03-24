import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/practice_session.dart';
import '../models/round.dart';
import '../services/practice_service.dart';
import '../services/round_service.dart';
import '../theme/app_theme.dart';
import 'round_detail_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final sw  = MediaQuery.of(context).size.width;
    final sh  = MediaQuery.of(context).size.height;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);

    return Stack(
      children: [
        StreamBuilder<List<PracticeSession>>(
          stream: PracticeService.practiceSessionsStream(),
          builder: (context, sessSnap) {
            return StreamBuilder<List<Round>>(
              stream: RoundService.practiceRoundsStream(),
              builder: (context, roundSnap) {
                final sessions = sessSnap.data ?? [];
                final practiceRounds = roundSnap.data ?? [];
                final isLoading =
                    (sessSnap.connectionState == ConnectionState.waiting && sessions.isEmpty) ||
                    (roundSnap.connectionState == ConnectionState.waiting && practiceRounds.isEmpty);

                if (isLoading) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: c.accent, strokeWidth: 2));
                }

                if (sessions.isEmpty && practiceRounds.isEmpty) {
                  return _buildEmpty(c, sw, sh);
                }

                // Build a unified list of items grouped by month.
                // Each item is either a PracticeSession or a Round (practice).
                final items = <({DateTime date, Object item})>[
                  for (final s in sessions) (date: s.date, item: s as Object),
                  for (final r in practiceRounds) (date: r.startedAt, item: r as Object),
                ]..sort((a, b) => b.date.compareTo(a.date));

                // Group by month
                final grouped = <String, List<({DateTime date, Object item})>>{};
                for (final e in items) {
                  final key = _monthKey(e.date);
                  grouped.putIfAbsent(key, () => []).add(e);
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(hPad, sh * 0.010, hPad, sh * 0.12),
                  children: [
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: sh * 0.010, top: sh * 0.016),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: c.tertiaryText,
                            fontSize: (sw * 0.028).clamp(10.0, 12.0),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      for (final e in entry.value)
                        if (e.item is PracticeSession)
                          _buildSessionCard(context, e.item as PracticeSession, c, sw, sh)
                        else
                          _buildRoundCard(context, e.item as Round, c, sw, sh),
                    ],
                  ],
                );
              },
            );
          },
        ),

        // FAB — Log Session only (Start Round moved to home screen FAB)
        Positioned(
          right: (sw * 0.055).clamp(18.0, 28.0),
          bottom: sh * 0.024,
          child: _FabWithLabel(
            icon: Icons.add_rounded,
            label: 'Log Session',
            color: const Color(0xFF5A9E1F),
            onPressed: () => _showLogSheet(context, c, sw, sh),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(AppColors c, double sw, double sh) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_golf_rounded,
              color: c.tertiaryText, size: (sw * 0.16).clamp(54.0, 72.0)),
          SizedBox(height: sh * 0.016),
          Text(
            'No practice sessions yet',
            style: TextStyle(
                color: c.secondaryText,
                fontSize: (sw * 0.042).clamp(15.0, 18.0),
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: sh * 0.008),
          Text(
            'Start a round to score holes,\nor log range and short-game sessions.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: c.tertiaryText,
                fontSize: (sw * 0.034).clamp(12.0, 15.0)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundCard(BuildContext context, Round round,
      AppColors c, double sw, double sh) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final diff  = round.scoreDiff;
    final diffLabel = diff == 0 ? 'E' : diff > 0 ? '+$diff' : '$diff';
    final diffColor = diff < 0
        ? const Color(0xFF8FD44E)
        : diff == 0
            ? const Color(0xFF64B5F6)
            : const Color(0xFFFF6B6B);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RoundDetailScreen(round: round)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: sh * 0.012),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
          boxShadow: c.cardShadow,
        ),
        padding: EdgeInsets.all((sw * 0.045).clamp(14.0, 20.0)),
        child: Row(
          children: [
            Container(
              width: (sw * 0.12).clamp(40.0, 52.0),
              height: (sw * 0.12).clamp(40.0, 52.0),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: diffColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${round.totalScore}',
                    style: TextStyle(fontFamily: 'Nunito',
                        color: diffColor,
                        fontSize: (sw * 0.04).clamp(13.0, 17.0),
                        fontWeight: FontWeight.w800,
                        height: 1.0),
                  ),
                  Text(diffLabel,
                      style: TextStyle(color: diffColor.withValues(alpha: 0.8),
                          fontSize: label * 0.85,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            SizedBox(width: (sw * 0.035).clamp(10.0, 16.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Scored Round',
                            style: TextStyle(
                                color: const Color(0xFF34D399),
                                fontSize: label * 0.85,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Text('${round.totalHoles}H',
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
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(round.startedAt),
                    style: TextStyle(color: c.secondaryText, fontSize: label),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.tertiaryText, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, PracticeSession session,
      AppColors c, double sw, double sh) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Session?'),
            content: const Text('This practice session will be permanently removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(color: Color(0xFFE53935))),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => PracticeService.deleteSession(session.id!),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFE53935), size: 24),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: sh * 0.012),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
          boxShadow: c.cardShadow,
        ),
        padding: EdgeInsets.all((sw * 0.045).clamp(14.0, 20.0)),
        child: Row(
          children: [
            Container(
              width: (sw * 0.12).clamp(40.0, 52.0),
              height: (sw * 0.12).clamp(40.0, 52.0),
              decoration: BoxDecoration(
                color: _typeColor(session.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(session.type),
                  color: _typeColor(session.type),
                  size: (sw * 0.06).clamp(20.0, 26.0)),
            ),
            SizedBox(width: (sw * 0.035).clamp(10.0, 16.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.type.label,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: body,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatDate(session.date),
                        style: TextStyle(
                            color: c.secondaryText, fontSize: label),
                      ),
                      if (session.durationMinutes != null) ...[
                        Text(' · ', style: TextStyle(color: c.tertiaryText)),
                        Text(
                          '${session.durationMinutes} min',
                          style: TextStyle(color: c.secondaryText, fontSize: label),
                        ),
                      ],
                      if (session.balls != null) ...[
                        Text(' · ', style: TextStyle(color: c.tertiaryText)),
                        Text(
                          '${session.balls} balls',
                          style: TextStyle(color: c.secondaryText, fontSize: label),
                        ),
                      ],
                    ],
                  ),
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      session.notes!,
                      style: TextStyle(color: c.tertiaryText, fontSize: label * 0.9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogSheet(
      BuildContext context, AppColors c, double sw, double sh) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LogSessionSheet(c: c, sw: sw, sh: sh),
    );
  }

  String _monthKey(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month]} ${d.year}'.toUpperCase();
  }

  String _formatDate(DateTime d) =>
      '${d.month}/${d.day}/${d.year}';

  Color _typeColor(PracticeType t) {
    switch (t) {
      case PracticeType.range:    return const Color(0xFF5A9E1F);
      case PracticeType.chipping: return const Color(0xFF34D399);
      case PracticeType.putting:  return const Color(0xFF8FD44E);
      case PracticeType.onCourse: return const Color(0xFFFFB74D);
    }
  }

  IconData _typeIcon(PracticeType t) {
    switch (t) {
      case PracticeType.range:    return Icons.sports_golf_rounded;
      case PracticeType.chipping: return Icons.flag_rounded;
      case PracticeType.putting:  return Icons.radio_button_checked_rounded;
      case PracticeType.onCourse: return Icons.terrain_rounded;
    }
  }
}

// ── Log Session Bottom Sheet ────────────────────────────────────────────────
class _LogSessionSheet extends StatefulWidget {
  final AppColors c;
  final double sw;
  final double sh;

  const _LogSessionSheet({required this.c, required this.sw, required this.sh});

  @override
  State<_LogSessionSheet> createState() => _LogSessionSheetState();
}

class _LogSessionSheetState extends State<_LogSessionSheet> {
  PracticeType _type = PracticeType.range;
  int? _balls;
  int? _duration;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  AppColors get c  => widget.c;
  double    get sw => widget.sw;
  double    get sh => widget.sh;

  @override
  void dispose() {
    _notesCtrl.dispose();
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
          Text('Log Practice Session',
              style: TextStyle(fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: (sw * 0.052).clamp(18.0, 22.0),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: sh * 0.022),

          // Type chips
          Text('Type', style: TextStyle(
              color: c.secondaryText, fontSize: label, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: PracticeType.values.map((t) {
              final sel = _type == t;
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF5A9E1F) : c.fieldBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? const Color(0xFF5A9E1F) : c.fieldBorder),
                  ),
                  child: Text(t.label,
                      style: TextStyle(
                          color: sel ? Colors.white : c.secondaryText,
                          fontSize: label,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: sh * 0.022),

          // Balls + Duration row
          Row(
            children: [
              Expanded(child: _numField(label, body, 'Balls hit', _balls, (v) => setState(() => _balls = v))),
              const SizedBox(width: 12),
              Expanded(child: _numField(label, body, 'Duration (min)', _duration, (v) => setState(() => _duration = v), step: 15)),
            ],
          ),
          SizedBox(height: sh * 0.018),

          // Notes
          Text('Notes (optional)', style: TextStyle(
              color: c.secondaryText, fontSize: label, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: c.fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.fieldBorder),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: TextStyle(color: c.primaryText, fontSize: body),
              decoration: InputDecoration(
                hintText: 'What did you work on?',
                hintStyle: TextStyle(color: c.tertiaryText, fontSize: body),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          SizedBox(height: sh * 0.028),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A9E1F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Save Session',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: body,
                          fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(double label, double body, String hint, int? value,
      void Function(int?) onChanged, {int step = 1}) {
    final c = this.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: TextStyle(
            color: c.secondaryText, fontSize: label, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.fieldBorder),
          ),
          child: Row(
            children: [
              _numBtn(Icons.remove_rounded,
                  value != null && value > 0
                      ? () => onChanged((value - step).clamp(0, 9999))
                      : null, c),
              Expanded(
                child: Center(
                  child: Text(
                    value != null ? '$value' : '-',
                    style: TextStyle(fontFamily: 'Nunito',
                        color: c.primaryText, fontSize: body, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              _numBtn(Icons.add_rounded,
                  () => onChanged((value ?? 0) + step), c),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numBtn(IconData icon, VoidCallback? onTap, AppColors c) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 44,
          alignment: Alignment.center,
          child: Icon(icon,
              color: onTap != null ? c.primaryText : c.tertiaryText, size: 18),
        ),
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await PracticeService.addSession(PracticeSession(
        userId: uid,
        date: DateTime.now(),
        type: _type,
        balls: _balls,
        durationMinutes: _duration,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── FAB with side label ────────────────────────────────────────────────────
class _FabWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _FabWithLabel({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.cardBorder),
              boxShadow: c.cardShadow,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: c.primaryText,
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
            mini: false,
            child: Icon(icon, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
