import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/round_summary_ai.dart';
import '../services/ai_round_summary_service.dart';
import '../theme/app_theme.dart';
import '../utils/calorie_calculator.dart';
import '../utils/l10n_extension.dart';
import '../widgets/ai_round_summary_card.dart';

// ---------------------------------------------------------------------------
// RoundSummaryScreen — full-page round complete summary
//
// Navigated to via Navigator.pushReplacement from ScorecardScreen so the
// back stack goes straight to Home when the user leaves this page.
// ---------------------------------------------------------------------------
class RoundSummaryScreen extends StatefulWidget {
  final String roundId;
  final String courseName;
  final int totalHoles;
  final int totalScore;
  final int totalPar;
  final int front9;
  final int back9;
  final int putts;
  final int fairwaysHit;
  final int fairwaysTotal;
  final int gir;
  final int birdies;
  final int pars;
  final int bogeys;
  final int doublePlus;
  final int bestHole;
  final int worstHole;
  final int durationMinutes;
  final bool carriedBag;

  const RoundSummaryScreen({
    super.key,
    required this.roundId,
    required this.courseName,
    required this.totalHoles,
    required this.totalScore,
    required this.totalPar,
    required this.front9,
    required this.back9,
    required this.putts,
    required this.fairwaysHit,
    required this.fairwaysTotal,
    required this.gir,
    required this.birdies,
    required this.pars,
    required this.bogeys,
    required this.doublePlus,
    required this.bestHole,
    required this.worstHole,
    this.durationMinutes = 0,
    this.carriedBag = true,
  });

  @override
  State<RoundSummaryScreen> createState() => _RoundSummaryScreenState();
}

class _RoundSummaryScreenState extends State<RoundSummaryScreen> {
  late final ConfettiController _confettiLeft;
  late final ConfettiController _confettiRight;
  late final Future<RoundSummaryAI> _aiFuture;

  int get _diff => widget.totalScore - widget.totalPar;
  String _diffLabel(BuildContext context) =>
      _diff == 0 ? context.l10n.roundSummaryEven : _diff > 0 ? '+$_diff' : '$_diff';

  @override
  void initState() {
    super.initState();
    _confettiLeft  = ConfettiController(duration: const Duration(seconds: 3));
    _confettiRight = ConfettiController(duration: const Duration(seconds: 3));

    final calories = CalorieCalculator.calculate(
      holesPlayed:     widget.totalHoles,
      carriedBag:      widget.carriedBag,
      usedCart:        !widget.carriedBag,
      durationMinutes: widget.durationMinutes,
    );

    _aiFuture = AIRoundSummaryService.generateSummary(
      roundId:       widget.roundId,
      courseName:    widget.courseName,
      totalHoles:    widget.totalHoles,
      score:         widget.totalScore,
      par:           widget.totalPar,
      front9:        widget.front9,
      back9:         widget.back9,
      putts:         widget.putts,
      fairwaysHit:   widget.fairwaysHit,
      fairwaysTotal: widget.fairwaysTotal,
      gir:           widget.gir,
      birdies:       widget.birdies,
      pars:          widget.pars,
      bogeys:        widget.bogeys,
      doublePlus:    widget.doublePlus,
      bestHole:      widget.bestHole,
      worstHole:     widget.worstHole,
      calories:      calories,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiLeft.play();
      _confettiRight.play();
    });
  }

  @override
  void dispose() {
    _confettiLeft.dispose();
    _confettiRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c  = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);
    final body = (sw * 0.036).clamp(13.0, 16.0);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: c.bgGradient,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, sh * 0.028, hPad, sh * 0.05),
              child: Column(
                children: [
                  // Trophy + title
                  SizedBox(height: sh * 0.02),
                  const Text('🏆', style: TextStyle(fontSize: 52)),
                  SizedBox(height: sh * 0.012),
                  Text(
                    context.l10n.roundSummaryComplete,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: (sw * 0.068).clamp(24.0, 32.0),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: sh * 0.004),
                  Text(
                    widget.courseName,
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: body,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: sh * 0.032),

                  // Score tiles
                  _buildScoreTiles(context, c, sw, sh, body),
                  SizedBox(height: sh * 0.028),

                  // AI summary card
                  FutureBuilder<RoundSummaryAI>(
                    future: _aiFuture,
                    builder: (_, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const AIRoundSummaryCard(isLoading: true);
                      }
                      return AIRoundSummaryCard(data: snap.data);
                    },
                  ),
                  SizedBox(height: sh * 0.036),

                  // Back to Home button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      height: (sh * 0.068).clamp(48.0, 60.0),
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7BC344), Color(0xFF5A9E1F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        shadows: const [
                          BoxShadow(
                            color: Color(0x445A9E1F),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        context.l10n.roundSummaryBackToHome,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: body,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti — top-left
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiLeft,
              blastDirection: 0.5,
              emissionFrequency: 0.08,
              numberOfParticles: 14,
              gravity: 0.3,
              colors: const [
                Color(0xFF4CAF82),
                Color(0xFF7BC344),
                Color(0xFFFFD700),
                Color(0xFFFFFFFF),
                Color(0xFF4E9E20),
              ],
            ),
          ),

          // Confetti — top-right
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiRight,
              blastDirection: 2.6,
              emissionFrequency: 0.08,
              numberOfParticles: 14,
              gravity: 0.3,
              colors: const [
                Color(0xFF4CAF82),
                Color(0xFF7BC344),
                Color(0xFFFFD700),
                Color(0xFFFFFFFF),
                Color(0xFF4E9E20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTiles(BuildContext context, AppColors c, double sw, double sh, double body) {
    final label = (sw * 0.030).clamp(11.0, 13.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _tile(c, sw, label, context.l10n.roundSummaryScore, '${widget.totalScore}'),
        _tile(c, sw, label, context.l10n.roundSummaryVsPar, _diffLabel(context),
            valueColor: _diff < 0
                ? c.accent
                : _diff == 0
                    ? null
                    : const Color(0xFFE53935)),
        _tile(c, sw, label, context.l10n.roundSummaryHoles, '${widget.totalHoles}'),
      ],
    );
  }

  Widget _tile(AppColors c, double sw, double label, String title, String value,
      {Color? valueColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Nunito',
            color: valueColor ?? c.primaryText,
            fontSize: (sw * 0.068).clamp(24.0, 32.0),
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(title,
            style: TextStyle(color: c.secondaryText, fontSize: label)),
      ],
    );
  }
}
