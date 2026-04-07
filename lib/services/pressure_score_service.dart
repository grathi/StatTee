import '../models/round.dart';
import '../models/hole_score.dart';
import '../models/pressure_profile.dart';

class PressureScoreService {
  // ── Weights (must sum to 100) ──────────────────────────────────────────────
  static const double _wOpening        = 14;
  static const double _wBirdie         = 18;
  static const double _wBackNine       = 22;
  static const double _wFinishing      = 22;
  static const double _wThreePutt      = 24;

  // ── Significance thresholds ───────────────────────────────────────────────
  static const double _sigDeltaStrokes  = 0.30; // strokes over baseline
  static const double _sigThreePuttRatio = 1.40; // 40% more three-putts
  static const int    _minSampleSize    = 3;
  static const int    _minRounds        = 5;

  /// Pure synchronous computation — no async, no Firestore.
  static PressureProfile compute(List<Round> rounds) {
    // Filter to completed rounds with at least some hole data
    final completed = rounds
        .where((r) => r.isComplete && r.scores.isNotEmpty)
        .toList();

    if (completed.length < _minRounds) {
      return PressureProfile(
        compositeScore:   100,
        roundsAnalyzed:   completed.length,
        baselineAvgDiff:  0,
        metrics:          [],
        hasEnoughData:    false,
      );
    }

    // ── Baseline: avg diff across every hole in every round ─────────────────
    final allHoles = completed.expand((r) => r.scores).toList();
    final baseline = allHoles.isEmpty
        ? 0.0
        : allHoles.map((h) => h.diff.toDouble()).reduce((a, b) => a + b) /
            allHoles.length;

    // ── Compute each metric ──────────────────────────────────────────────────
    final opening   = _openingHole(completed, baseline);
    final birdie    = _birdieHangover(completed, baseline);
    final backNine  = _backNineDecay(completed);
    final finishing = _finishingStretch(completed, baseline);
    final threePutt = _threePuttTiming(completed);

    final metrics = [opening, birdie, backNine, finishing, threePutt];

    // ── Composite score ──────────────────────────────────────────────────────
    double penalty = 0;

    // Each significant metric deducts its weight × a normalized delta factor.
    // Factor is clamped at 1.0 so one bad metric can't wipe the whole score.
    void applyPenalty(PressureMetric m, double weight, double normDivisor) {
      if (!m.isSignificant) return;
      final factor = (m.delta.abs() / normDivisor).clamp(0.0, 1.0);
      penalty += weight * factor;
    }

    applyPenalty(opening,   _wOpening,   1.5);  // 1.5 strokes = full penalty
    applyPenalty(birdie,    _wBirdie,    1.5);
    applyPenalty(backNine,  _wBackNine,  1.5);
    applyPenalty(finishing, _wFinishing, 1.5);
    // Three-putt: ratio of 2.5× or more = full penalty
    if (threePutt.isSignificant) {
      final factor = ((threePutt.delta - 1.0) / 1.5).clamp(0.0, 1.0);
      penalty += _wThreePutt * factor;
    }

    final composite = (100 - penalty).clamp(0.0, 100.0).round();

    return PressureProfile(
      compositeScore:  composite,
      roundsAnalyzed:  completed.length,
      baselineAvgDiff: baseline,
      metrics:         metrics,
      hasEnoughData:   true,
    );
  }

  // ── Metric 1: Opening Hole Syndrome ────────────────────────────────────────
  static PressureMetric _openingHole(List<Round> rounds, double baseline) {
    final firstHoles = rounds
        .expand((r) => r.scores.where((h) => h.hole == 1))
        .toList();

    final n = firstHoles.length;
    if (n < _minSampleSize) return _insufficientMetric(kMetricOpeningHole, 'Opening Hole');

    final avg = firstHoles.map((h) => h.diff.toDouble()).reduce((a, b) => a + b) / n;
    final delta = avg - baseline;
    final significant = delta > _sigDeltaStrokes;

    return PressureMetric(
      id:             kMetricOpeningHole,
      label:          'Opening Hole',
      delta:          delta,
      sampleSize:     n,
      isSignificant:  significant,
      penaltyApplied: significant ? _wOpening * (delta.abs() / 1.5).clamp(0.0, 1.0) : 0,
    );
  }

  // ── Metric 2: Birdie Hangover ───────────────────────────────────────────────
  static PressureMetric _birdieHangover(List<Round> rounds, double baseline) {
    final postBirdieHoles = <HoleScore>[];

    for (final round in rounds) {
      final scores = round.scores;
      for (int i = 0; i < scores.length - 1; i++) {
        if (scores[i].isBirdie) {
          postBirdieHoles.add(scores[i + 1]);
        }
      }
    }

    final n = postBirdieHoles.length;
    if (n < _minSampleSize) return _insufficientMetric(kMetricBirdieHangover, 'Birdie Hangover');

    final avg = postBirdieHoles.map((h) => h.diff.toDouble()).reduce((a, b) => a + b) / n;
    final delta = avg - baseline;
    final significant = delta > _sigDeltaStrokes;

    return PressureMetric(
      id:             kMetricBirdieHangover,
      label:          'Birdie Hangover',
      delta:          delta,
      sampleSize:     n,
      isSignificant:  significant,
      penaltyApplied: significant ? _wBirdie * (delta.abs() / 1.5).clamp(0.0, 1.0) : 0,
    );
  }

  // ── Metric 3: Back-Nine Decay ──────────────────────────────────────────────
  static PressureMetric _backNineDecay(List<Round> rounds) {
    // Only use 18-hole rounds for this metric
    final eighteenHole = rounds.where((r) => r.totalHoles >= 18).toList();

    final frontNine = <HoleScore>[];
    final backNine  = <HoleScore>[];

    for (final r in eighteenHole) {
      for (final h in r.scores) {
        if (h.hole >= 1  && h.hole <= 9)  frontNine.add(h);
        if (h.hole >= 10 && h.hole <= 18) backNine.add(h);
      }
    }

    final n = backNine.length;
    if (frontNine.length < _minSampleSize || n < _minSampleSize) {
      return _insufficientMetric(kMetricBackNine, 'Back-Nine Decay');
    }

    final frontAvg = frontNine.map((h) => h.diff.toDouble()).reduce((a, b) => a + b) / frontNine.length;
    final backAvg  = backNine.map((h)  => h.diff.toDouble()).reduce((a, b) => a + b) / n;
    final delta = backAvg - frontAvg;
    final significant = delta > _sigDeltaStrokes;

    return PressureMetric(
      id:             kMetricBackNine,
      label:          'Back-Nine Decay',
      delta:          delta,
      sampleSize:     n,
      isSignificant:  significant,
      penaltyApplied: significant ? _wBackNine * (delta.abs() / 1.5).clamp(0.0, 1.0) : 0,
    );
  }

  // ── Metric 4: Finishing Stretch Collapse ───────────────────────────────────
  static PressureMetric _finishingStretch(List<Round> rounds, double baseline) {
    final finishingHoles = <HoleScore>[];

    for (final r in rounds) {
      final total = r.totalHoles;
      // Last 3 holes of the round
      final lastHoleNumbers = {total - 2, total - 1, total};
      finishingHoles.addAll(r.scores.where((h) => lastHoleNumbers.contains(h.hole)));
    }

    final n = finishingHoles.length;
    if (n < _minSampleSize) return _insufficientMetric(kMetricFinishingStretch, 'Finishing Stretch');

    final avg = finishingHoles.map((h) => h.diff.toDouble()).reduce((a, b) => a + b) / n;
    final delta = avg - baseline;
    final significant = delta > _sigDeltaStrokes;

    return PressureMetric(
      id:             kMetricFinishingStretch,
      label:          'Finishing Stretch',
      delta:          delta,
      sampleSize:     n,
      isSignificant:  significant,
      penaltyApplied: significant ? _wFinishing * (delta.abs() / 1.5).clamp(0.0, 1.0) : 0,
    );
  }

  // ── Metric 5: Three-Putt Timing ────────────────────────────────────────────
  static PressureMetric _threePuttTiming(List<Round> rounds) {
    // Only include holes where putts were recorded (putts > 0)
    final pressureHoles = <HoleScore>[];  // holes 1–3 or last 3
    final otherHoles    = <HoleScore>[];

    for (final r in rounds) {
      final total = r.totalHoles;
      final pressureNums = {1, 2, 3, total - 2, total - 1, total};
      for (final h in r.scores) {
        if (h.putts == 0) continue; // not recorded
        if (pressureNums.contains(h.hole)) {
          pressureHoles.add(h);
        } else {
          otherHoles.add(h);
        }
      }
    }

    final n = pressureHoles.length;
    if (n < _minSampleSize || otherHoles.length < _minSampleSize) {
      return _insufficientMetric(kMetricThreePutt, 'Three-Putt Timing');
    }

    final pressureRate = pressureHoles.where((h) => h.putts >= 3).length / n;
    final otherRate    = otherHoles.where((h) => h.putts >= 3).length / otherHoles.length;

    // Ratio: how many times more likely to three-putt on pressure holes
    final ratio = otherRate == 0 ? (pressureRate > 0 ? 2.5 : 1.0) : pressureRate / otherRate;
    final significant = ratio > _sigThreePuttRatio;

    return PressureMetric(
      id:             kMetricThreePutt,
      label:          'Three-Putt Timing',
      delta:          ratio,
      sampleSize:     n,
      isSignificant:  significant,
      penaltyApplied: significant ? _wThreePutt * ((ratio - 1.0) / 1.5).clamp(0.0, 1.0) : 0,
    );
  }

  // ── Helper ─────────────────────────────────────────────────────────────────
  static PressureMetric _insufficientMetric(String id, String label) => PressureMetric(
        id:             id,
        label:          label,
        delta:          0,
        sampleSize:     0,
        isSignificant:  false,
        penaltyApplied: 0,
      );
}
