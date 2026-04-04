import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/group_round.dart';
import '../services/group_round_service.dart';
import '../services/round_service.dart';
import '../theme/app_theme.dart';
import 'scorecard_import_screen.dart';
import 'scorecard_screen.dart';

class GroupRoundInviteScreen extends StatefulWidget {
  const GroupRoundInviteScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<GroupRoundInviteScreen> createState() => _GroupRoundInviteScreenState();
}

class _GroupRoundInviteScreenState extends State<GroupRoundInviteScreen> {
  bool _joining = false;

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
          child: StreamBuilder<GroupRound>(
            stream: GroupRoundService.sessionStream(widget.sessionId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(
                    child: CircularProgressIndicator(
                        color: c.accent, strokeWidth: 2));
              }
              final session = snap.data!;
              final cancelled = session.status == 'cancelled';
              final myEntry = session.players.values
                  .cast<GroupRoundPlayer?>()
                  .firstWhere(
                    (p) => p?.uid == _myUid,
                    orElse: () => null,
                  );
              final alreadyJoined =
                  myEntry?.status == 'joined' || myEntry?.status == 'completed';
              final declined = myEntry?.status == 'declined';
              final isLateJoin = !alreadyJoined && !declined && !cancelled &&
                  (session.status == 'active' || session.status == 'completed');

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, sh * 0.06, hPad, sh * 0.04),
                child: Column(
                  children: [
                    // Golf icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)]),
                        shape: SuperellipseShape(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Center(
                          child: Text('⛳', style: TextStyle(fontSize: 36))),
                    ),
                    SizedBox(height: sh * 0.022),

                    Text(
                      '${session.hostName} invites you\nto play a round!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: (sw * 0.055).clamp(18.0, 24.0),
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: sh * 0.022),

                    // Course card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: ShapeDecoration(
                        color: c.cardBg,
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: c.cardBorder),
                        ),
                        shadows: c.cardShadow,
                      ),
                      child: Column(
                        children: [
                          _infoRow(c, body, label, Icons.golf_course_rounded,
                              'Course', session.courseName),
                          if (session.courseLocation.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _infoRow(c, body, label, Icons.location_on_rounded,
                                'Location', session.courseLocation),
                          ],
                          const SizedBox(height: 10),
                          _infoRow(c, body, label, Icons.flag_rounded,
                              'Holes', '${session.totalHoles} holes'),
                        ],
                      ),
                    ),
                    SizedBox(height: sh * 0.018),

                    // Who else is playing
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: ShapeDecoration(
                        color: c.cardBg,
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: c.cardBorder),
                        ),
                        shadows: c.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Players',
                              style: TextStyle(
                                  color: c.tertiaryText,
                                  fontSize: label,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 10),
                          ...session.players.values.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    _AvatarSm(
                                        url: p.avatarUrl,
                                        name: p.displayName),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        p.uid == session.hostUid
                                            ? '${p.displayName} (host)'
                                            : p.displayName,
                                        style: TextStyle(
                                            color: c.primaryText,
                                            fontSize: body,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    _statusBadge(c, label, p.status),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    SizedBox(height: sh * 0.03),

                    if (cancelled) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: c.fieldBg,
                          shape: SuperellipseShape(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: c.fieldBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel_outlined,
                                color: c.tertiaryText, size: body * 1.2),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('This round has been cancelled',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: c.tertiaryText,
                                      fontSize: body,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          height: (sh * 0.064).clamp(48.0, 58.0),
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            color: c.fieldBg,
                            shape: SuperellipseShape(
                              borderRadius: BorderRadius.circular(48),
                              side: BorderSide(color: c.fieldBorder),
                            ),
                          ),
                          child: Text('Go Back',
                              style: TextStyle(
                                  color: c.tertiaryText,
                                  fontSize: (sw * 0.040).clamp(14.0, 17.0),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ] else if (!alreadyJoined && !declined && !isLateJoin) ...[
                      // Join button
                      GestureDetector(
                        onTap: _joining ? null : () => _join(context, session),
                        child: Container(
                          width: double.infinity,
                          height: (sh * 0.072).clamp(52.0, 64.0),
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)]),
                            shape: SuperellipseShape(
                                borderRadius: BorderRadius.circular(48)),
                            shadows: [
                              BoxShadow(
                                color:
                                    const Color(0xFF5A9E1F).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: _joining
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.sports_golf_rounded,
                                        color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Text('Join Round',
                                        style: TextStyle(
                                            fontFamily: 'Nunito',
                                            color: Colors.white,
                                            fontSize: (sw * 0.046).clamp(
                                                15.0, 19.0),
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Decline button
                      GestureDetector(
                        onTap: () => _decline(context),
                        child: Container(
                          width: double.infinity,
                          height: (sh * 0.064).clamp(48.0, 58.0),
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            color: c.fieldBg,
                            shape: SuperellipseShape(
                              borderRadius: BorderRadius.circular(48),
                              side: BorderSide(color: c.fieldBorder),
                            ),
                          ),
                          child: Text('Decline',
                              style: TextStyle(
                                  color: c.tertiaryText,
                                  fontSize: (sw * 0.040).clamp(14.0, 17.0),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ] else if (alreadyJoined) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: c.accentBg,
                          shape: SuperellipseShape(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: c.accentBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: c.accent, size: body * 1.2),
                            const SizedBox(width: 8),
                            Text("You've joined this round",
                                style: TextStyle(
                                    color: c.accent,
                                    fontSize: body,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ] else if (isLateJoin) ...[
                      // Join Round button (live scoring)
                      GestureDetector(
                        onTap: _joining ? null : () => _join(context, session),
                        child: Container(
                          width: double.infinity,
                          height: (sh * 0.072).clamp(52.0, 64.0),
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF5A9E1F), Color(0xFF8FD44E)]),
                            shape: SuperellipseShape(
                                borderRadius: BorderRadius.circular(48)),
                            shadows: [
                              BoxShadow(
                                color: const Color(0xFF5A9E1F).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: _joining
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.sports_golf_rounded,
                                        color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Text('Join Round',
                                        style: TextStyle(
                                            fontFamily: 'Nunito',
                                            color: Colors.white,
                                            fontSize: (sw * 0.046).clamp(15.0, 19.0),
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Upload Scorecard button
                      GestureDetector(
                        onTap: _joining ? null : () => _lateJoin(context, session),
                        child: Container(
                          width: double.infinity,
                          height: (sh * 0.064).clamp(48.0, 58.0),
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            color: c.fieldBg,
                            shape: SuperellipseShape(
                              borderRadius: BorderRadius.circular(48),
                              side: BorderSide(color: c.accentBorder),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file_rounded,
                                  color: c.accent, size: 20),
                              const SizedBox(width: 8),
                              Text('Upload Scorecard',
                                  style: TextStyle(
                                      fontFamily: 'Nunito',
                                      color: c.accent,
                                      fontSize: (sw * 0.040).clamp(14.0, 17.0),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Decline button
                      GestureDetector(
                        onTap: () => _decline(context),
                        child: Container(
                          width: double.infinity,
                          height: (sh * 0.064).clamp(48.0, 58.0),
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            color: c.fieldBg,
                            shape: SuperellipseShape(
                              borderRadius: BorderRadius.circular(48),
                              side: BorderSide(color: c.fieldBorder),
                            ),
                          ),
                          child: Text('Decline',
                              style: TextStyle(
                                  color: c.tertiaryText,
                                  fontSize: (sw * 0.040).clamp(14.0, 17.0),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ] else ...[
                      Text('You declined this invite.',
                          style: TextStyle(
                              color: c.tertiaryText, fontSize: body)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _join(BuildContext context, GroupRound session) async {
    setState(() => _joining = true);
    try {
      // Re-fetch the session to make sure it hasn't been cancelled
      // between the time the invite screen opened and the user tapped Join.
      final latest = await GroupRoundService.fetchSession(widget.sessionId);
      if (latest == null || latest.status == 'cancelled') {
        if (mounted) setState(() => _joining = false);
        return;
      }

      final roundId = await RoundService.startRound(
        courseName:   session.courseName,
        courseLocation: session.courseLocation,
        totalHoles:   session.totalHoles,
        courseRating: session.courseRating,
        slopeRating:  session.slopeRating,
      );
      await GroupRoundService.joinSession(widget.sessionId, roundId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScorecardScreen(
            roundId:        roundId,
            courseName:     session.courseName,
            totalHoles:     session.totalHoles,
            sessionId:      widget.sessionId,
            preloadedHoles: session.holes.isNotEmpty ? session.holes : null,
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _decline(BuildContext context) async {
    await GroupRoundService.declineInvite(widget.sessionId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _lateJoin(BuildContext context, GroupRound session) async {
    setState(() => _joining = true);
    try {
      final latest = await GroupRoundService.fetchSession(widget.sessionId);
      if (latest == null || latest.status == 'cancelled') {
        if (mounted) setState(() => _joining = false);
        return;
      }
      if (!mounted) return;
      setState(() => _joining = false);
      if (!context.mounted) return;
      await showScorecardImportFlow(
        context,
        sessionId: widget.sessionId,
        session: session,
      );
    } catch (_) {
      if (mounted) setState(() => _joining = false);
    }
  }

  Widget _infoRow(AppColors c, double body, double label, IconData icon,
      String lbl, String value) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: ShapeDecoration(
            color: c.accentBg,
            shape:
                SuperellipseShape(borderRadius: BorderRadius.circular(12)),
          ),
          child: Icon(icon, color: c.accent, size: body),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lbl,
                  style: TextStyle(
                      color: c.tertiaryText,
                      fontSize: label * 0.9,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: c.primaryText,
                    fontSize: body,
                    fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(AppColors c, double label, String status) {
    Color color;
    String text;
    switch (status) {
      case 'joined':
        color = c.accent;
        text = 'Joined';
      case 'completed':
        color = const Color(0xFF3B82F6);
        text = 'Done';
      case 'declined':
        color = c.tertiaryText;
        text = 'Declined';
      default:
        color = const Color(0xFFF59E0B);
        text = 'Invited';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: label * 0.9,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _AvatarSm extends StatelessWidget {
  const _AvatarSm({required this.name, this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    final c = AppColors.of(context);
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(url!, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initials(c)),
      );
    }
    return _initials(c);
  }

  Widget _initials(AppColors c) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: c.accentBg, shape: BoxShape.circle),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: c.accent,
                fontSize: 13,
                fontWeight: FontWeight.w800),
          ),
        ),
      );
}
