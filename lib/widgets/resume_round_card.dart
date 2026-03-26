import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';

import '../models/round.dart';
import '../services/round_service.dart';
import '../screens/scorecard_screen.dart';
import '../theme/app_theme.dart';

const String _kResumeRoundImageUrl =
    'https://cdn.jsdelivr.net/gh/grathi/stattee_profile_pic@136375cecb56c767709935a7cf5775da6c3396ee/resume_round.png';
/// Provides Resume and Discard actions.
class ResumeRoundCard extends StatelessWidget {
  final Round round;

  const ResumeRoundCard({super.key, required this.round});

  // ── Resume ────────────────────────────────────────────────────────────────

  void _resume(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScorecardScreen(
          roundId: round.id!,
          courseName: round.courseName,
          totalHoles: round.totalHoles,
          initialHole: round.currentHole,
          savedScores: round.scores,
        ),
      ),
    );
  }

  // ── Discard ───────────────────────────────────────────────────────────────

  Future<void> _confirmDiscard(BuildContext context) async {
    final c = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogCtx) {
        final sw = MediaQuery.of(dialogCtx).size.width;
        final dialogBody = (sw * 0.038).clamp(13.0, 16.0);
        final btnH = (sw * 0.125).clamp(44.0, 52.0);
        final iconSz = (sw * 0.14).clamp(48.0, 58.0);
        return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: ShapeDecoration(
            color: c.sheetBg,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(56),
              side: BorderSide(color: c.cardBorder),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            (sw * 0.06).clamp(20.0, 28.0),
            (sw * 0.07).clamp(24.0, 32.0),
            (sw * 0.06).clamp(20.0, 28.0),
            (sw * 0.05).clamp(18.0, 24.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSz,
                height: iconSz,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: const Color(0xFFE53935), size: iconSz * 0.46),
              ),
              SizedBox(height: sw * 0.04),
              Text(
                'Discard Round?',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: c.primaryText,
                  fontSize: (sw * 0.052).clamp(18.0, 22.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: sw * 0.02),
              Text(
                'All progress on "${round.courseName}" will be permanently lost.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.secondaryText,
                  fontSize: dialogBody * 0.9,
                  height: 1.5,
                ),
              ),
              SizedBox(height: sw * 0.06),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: btnH,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.primaryText,
                          side: BorderSide(color: c.cardBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Keep',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: dialogBody,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: btnH,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.10),
                          foregroundColor: const Color(0xFFE53935),
                          elevation: 0,
                          side: BorderSide(color: const Color(0xFFE53935).withValues(alpha: 0.30)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Discard',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: dialogBody,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      },
    );

    if (confirmed == true) {
      await RoundService.abandonRound(round.id!);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw    = MediaQuery.of(context).size.width;
    final hPad  = (sw * 0.055).clamp(18.0, 28.0);
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final btnH  = (sw * 0.115).clamp(40.0, 48.0);
    final holesPlayed = round.scores.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Container(
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A08), Color(0xFF2E5E10), Color(0xFF3D7A14)],
            stops: [0.0, 0.5, 1.0],
          ),
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(40)),
          shadows: [
            BoxShadow(
              color: const Color(0xFF3D7A14).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.052).clamp(14.0, 20.0),
          vertical: (sw * 0.038).clamp(12.0, 16.0),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Image — bottom-right ──────────────────────────────────────
            Positioned(
              right: -(sw * 0.02).clamp(6.0, 10.0),
              bottom: -(sw * 0.04).clamp(10.0, 16.0),
              width: (sw * 0.38).clamp(120.0, 158.0),
              height: (sw * 0.38).clamp(120.0, 158.0),
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.92,
                  child: Image.network(
                    _kResumeRoundImageUrl,
                    fit: BoxFit.contain,
                    frameBuilder: (_, child, frame, wasSynchronous) {
                      if (wasSynchronous || frame != null) return child;
                      return const SizedBox.shrink();
                    },
                    errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // ── Delete icon — top-right ───────────────────────────────────
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _confirmDiscard(context),
                child: Container(
                  width: btnH * 0.82,
                  height: btnH * 0.82,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.70),
                    size: body * 1.15,
                  ),
                ),
              ),
            ),

            // ── Foreground content ────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                // ── Header ───────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(right: (sw * 0.14).clamp(44.0, 56.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unfinished Round',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: label,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        round.courseName,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: body * 1.05,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$holesPlayed / ${round.totalHoles} holes played',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: body,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Resume button — left-aligned ──────────────────────────
                GestureDetector(
                  onTap: () => _resume(context),
                  child: Container(
                    height: btnH,
                    padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.052).clamp(14.0, 20.0)),
                    decoration: ShapeDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7BC344), Color(0xFF5A9E1F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: SuperellipseShape(borderRadius: BorderRadius.circular(24)),
                      shadows: [
                        BoxShadow(
                          color: const Color(0xFF5A9E1F).withValues(alpha: 0.40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Resume Round',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontSize: body,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


