import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/pressure_profile.dart';
import '../models/pressure_narrative.dart';
import '../services/pressure_score_service.dart';
import '../services/ai_pressure_narrative_service.dart';
import '../screens/pressure_score_screen.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';

/// Compact card shown in the Stats tab.
class PressureScoreCard extends StatefulWidget {
  final List rounds; // List<Round> — typed loosely to avoid import cycle

  const PressureScoreCard({super.key, required this.rounds});

  @override
  State<PressureScoreCard> createState() => _PressureScoreCardState();
}

class _PressureScoreCardState extends State<PressureScoreCard> {
  PressureNarrative? _narrative;
  bool _loadingNarrative = false;

  late PressureProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = PressureScoreService.compute(List.from(widget.rounds));
    if (_profile.hasEnoughData) _fetchNarrative();
  }

  @override
  void didUpdateWidget(PressureScoreCard old) {
    super.didUpdateWidget(old);
    if (widget.rounds.length != old.rounds.length) {
      _profile = PressureScoreService.compute(List.from(widget.rounds));
      if (_profile.hasEnoughData && _narrative == null) _fetchNarrative();
    }
  }

  Future<void> _fetchNarrative() async {
    if (_loadingNarrative) return;
    setState(() => _loadingNarrative = true);
    final n = await AIPressureNarrativeService.generate(_profile);
    if (mounted) setState(() { _narrative = n; _loadingNarrative = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c  = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    return _profile.hasEnoughData
        ? _buildUnlocked(context, c, sw)
        : _buildLocked(context, c, sw);
  }

  // ── Locked state ────────────────────────────────────────────────────────────
  Widget _buildLocked(BuildContext context, AppColors c, double sw) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);
    final remaining = (5 - _profile.roundsAnalyzed).clamp(1, 5);

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          colors: c.cardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Row(
        children: [
          Container(
            width: (sw * 0.12).clamp(42.0, 52.0),
            height: (sw * 0.12).clamp(42.0, 52.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.iconContainerBg,
              border: Border.all(color: c.iconContainerBorder),
            ),
            child: Icon(Icons.lock_rounded, color: c.tertiaryText, size: (sw * 0.055).clamp(18.0, 24.0)),
          ),
          SizedBox(width: (sw * 0.040).clamp(12.0, 18.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.statsPressureScore,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.statsPressureUnlockHint(remaining),
                  style: TextStyle(color: c.secondaryText, fontSize: label),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Unlocked state ──────────────────────────────────────────────────────────
  Widget _buildUnlocked(BuildContext context, AppColors c, double sw) {
    final body   = (sw * 0.036).clamp(13.0, 16.0);
    final label  = (sw * 0.030).clamp(11.0, 13.0);
    final score  = _profile.compositeScore;
    final scoreColor = score >= 75
        ? const Color(0xFF5A9E1F)
        : score >= 50
            ? const Color(0xFFFFB74D)
            : const Color(0xFFE53935);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PressureScoreScreen(
            profile:   _profile,
            narrative: _narrative,
          ),
        ),
      ),
      child: Container(
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            colors: c.cardGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(48),
            side: BorderSide(color: c.cardBorder),
          ),
          shadows: c.cardShadow,
        ),
        padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row + score ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.statsPressureScore,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: scoreColor,
                        fontSize: (sw * 0.068).clamp(24.0, 32.0),
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      context.l10n.statsPressureResilience,
                      style: TextStyle(color: c.tertiaryText, fontSize: label * 0.85),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── AI headline ───────────────────────────────────────────────
            Skeletonizer(
              enabled: _loadingNarrative,
              child: Text(
                _narrative?.headline ?? (_loadingNarrative ? 'Analyzing your pressure patterns...' : ''),
                style: TextStyle(
                  color: c.secondaryText,
                  fontSize: label,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 14),
            // ── 5 metric dots ─────────────────────────────────────────────
            _buildMetricDots(context, c, sw, label),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricDots(BuildContext context, AppColors c, double sw, double label) {
    const ids = [
      kMetricOpeningHole,
      kMetricBirdieHangover,
      kMetricBackNine,
      kMetricFinishingStretch,
      kMetricThreePutt,
    ];

    String shortLabel(String id) {
      switch (id) {
        case kMetricOpeningHole:       return context.l10n.statsPressureOpeningHole;
        case kMetricBirdieHangover:    return context.l10n.statsPressureBirdieHangover;
        case kMetricBackNine:          return context.l10n.statsPressureBackNine;
        case kMetricFinishingStretch:  return context.l10n.statsPressureFinishingStretch;
        case kMetricThreePutt:         return context.l10n.statsPressureThreePutt;
        default: return id;
      }
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final id in ids)
          Builder(builder: (context) {
            final m = _profile.metricById(id);
            final problem = m?.isSignificant ?? false;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: problem
                        ? const Color(0xFFE53935)
                        : c.tertiaryText.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  shortLabel(id),
                  style: TextStyle(
                    color: problem ? c.primaryText : c.tertiaryText,
                    fontSize: label * 0.88,
                    fontWeight: problem ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }),
        Icon(Icons.chevron_right_rounded, color: c.tertiaryText, size: label + 4),
      ],
    );
  }
}
