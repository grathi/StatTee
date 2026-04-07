// Pressure metric IDs
const kMetricOpeningHole       = 'opening_hole';
const kMetricBirdieHangover    = 'birdie_hangover';
const kMetricBackNine          = 'back_nine';
const kMetricFinishingStretch  = 'finishing_stretch';
const kMetricThreePutt         = 'three_putt';

class PressureMetric {
  final String id;
  final String label;

  /// Positive = worse under pressure (extra strokes vs baseline).
  /// For three_putt this is the ratio (e.g. 1.8 means 80% more three-putts).
  final double delta;

  final int sampleSize;
  final bool isSignificant;

  /// Points deducted from the 100-point composite score.
  final double penaltyApplied;

  const PressureMetric({
    required this.id,
    required this.label,
    required this.delta,
    required this.sampleSize,
    required this.isSignificant,
    required this.penaltyApplied,
  });
}

class PressureProfile {
  final int compositeScore;       // 0–100
  final int roundsAnalyzed;
  final double baselineAvgDiff;   // overall avg score-vs-par per hole
  final List<PressureMetric> metrics;
  final bool hasEnoughData;       // roundsAnalyzed >= 5

  const PressureProfile({
    required this.compositeScore,
    required this.roundsAnalyzed,
    required this.baselineAvgDiff,
    required this.metrics,
    required this.hasEnoughData,
  });

  /// Empty profile for the locked / insufficient-data state.
  const PressureProfile.empty()
      : compositeScore = 0,
        roundsAnalyzed = 0,
        baselineAvgDiff = 0,
        metrics = const [],
        hasEnoughData = false;

  PressureMetric? metricById(String id) {
    try {
      return metrics.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
