import 'dart:math' as math;
import '../models/play_style_identity.dart';
import '../models/round.dart';

class _Scores {
  final double risk;
  final double consistency;
  final double putting;
  final double accuracy;
  const _Scores({
    required this.risk,
    required this.consistency,
    required this.putting,
    required this.accuracy,
  });
}

class PlayStyleService {
  /// Compute a [PlayStyleIdentity] from the most recent rounds.
  /// Looks at up to the last 5 completed rounds.
  static PlayStyleIdentity compute(List<Round> rounds) {
    final recent = rounds.take(5).toList();
    if (recent.isEmpty) return _build(PlayStyleType.weekendGolfer, 0);

    final scores = _computeScores(recent);
    final type   = _classify(scores, recent);

    // Confidence: based on how many rounds fed the model (5 = full confidence)
    final confidence = (recent.length / 5.0 * 100).round().clamp(20, 100);

    return _build(type, confidence);
  }

  // ── Score derivation ───────────────────────────────────────────────────────

  static _Scores _computeScores(List<Round> rounds) {
    // riskScore = (birdies*2 + bogeys*1.5) per hole, normalised 0–100
    double totalRiskPoints = 0;
    double totalHoles      = 0;
    double totalPutts      = 0;
    int    totalHolesForPutts = 0;
    double totalFairwayPct = 0;
    double totalGirPct     = 0;

    for (final r in rounds) {
      if (r.scores.isEmpty) continue;
      final holes = r.scores.length.toDouble();
      totalRiskPoints += r.birdies * 2.0 + r.bogeys * 1.5;
      totalHoles      += holes;
      totalPutts      += r.totalPutts;
      totalHolesForPutts += r.scores.length;
      totalFairwayPct += r.fairwaysHitPct;
      totalGirPct     += r.girPct;
    }

    // Risk: normalised so ~0.5 risk pts/hole → 50, capped at 100
    final riskPerHole  = totalHoles > 0 ? totalRiskPoints / totalHoles : 0.0;
    final risk         = (riskPerHole * 100.0).clamp(0.0, 100.0);

    // Putting: avg putts/hole — 1.5 → 100, 2.5 → 0 (linear inverse)
    final avgPutts = totalHolesForPutts > 0
        ? totalPutts / totalHolesForPutts
        : 2.0;
    final putting = ((2.5 - avgPutts) / 1.0 * 100.0).clamp(0.0, 100.0);

    // Accuracy: average of fairways % and GIR %
    final n = rounds.where((r) => r.scores.isNotEmpty).length;
    final avgFairway = n > 0 ? totalFairwayPct / n : 30.0;
    final avgGir     = n > 0 ? totalGirPct / n     : 20.0;
    final accuracy   = ((avgFairway + avgGir) / 2.0).clamp(0.0, 100.0);

    // Consistency: inverse of score-diff variance across rounds
    final diffs = rounds
        .where((r) => r.scores.isNotEmpty)
        .map((r) => r.scoreDiff.toDouble())
        .toList();
    double consistency = 60.0;
    if (diffs.length >= 2) {
      final mean     = diffs.fold(0.0, (s, v) => s + v) / diffs.length;
      final variance = diffs.fold(0.0, (s, v) => s + math.pow(v - mean, 2)) /
          diffs.length;
      // variance of 0 → 100, variance of 25+ → 0
      consistency = (100.0 - (variance / 25.0 * 100.0)).clamp(0.0, 100.0);
    }

    return _Scores(
      risk:        risk,
      consistency: consistency,
      putting:     putting,
      accuracy:    accuracy,
    );
  }

  // ── Rule-based classifier ──────────────────────────────────────────────────

  static PlayStyleType _classify(_Scores s, List<Round> rounds) {
    final birdiesPerRound = rounds.isEmpty
        ? 0.0
        : rounds.fold(0, (sum, r) => sum + r.birdies) / rounds.length;

    // Rule order matters — most specific first
    if (s.risk >= 55 && birdiesPerRound >= 1.2) {
      return PlayStyleType.aggressiveStriker;
    }
    if (s.consistency >= 65 && s.accuracy >= 55) {
      return PlayStyleType.consistentPlayer;
    }
    if (s.putting >= 65) {
      return PlayStyleType.shortGameMaster;
    }
    if (s.risk <= 30 && s.accuracy >= 50) {
      return PlayStyleType.safePlayer;
    }
    if (s.accuracy >= 50 || s.consistency >= 50) {
      return PlayStyleType.strategicPlayer;
    }
    return PlayStyleType.weekendGolfer;
  }

  // ── Identity definitions ───────────────────────────────────────────────────

  static PlayStyleIdentity _build(PlayStyleType type, int confidence) {
    final now = DateTime.now();
    switch (type) {
      case PlayStyleType.aggressiveStriker:
        return PlayStyleIdentity(
          type:            type,
          title:           'Aggressive Striker',
          description:     'You play to score. Bold shot selection, fearless approach play, and a higher-risk strategy define your game. You\'d rather chase birdie than settle for bogey.',
          traits:          ['Birdie Hunter', 'Bold Shot Selection', 'High Risk', 'Power Game'],
          confidenceScore: confidence,
          lastUpdated:     now,
        );
      case PlayStyleType.strategicPlayer:
        return PlayStyleIdentity(
          type:            type,
          title:           'Strategic Player',
          description:     'You think before you swing. Course management and smart positioning let you turn mediocre ball-striking into consistent scoring.',
          traits:          ['Course Manager', 'Smart Positioning', 'Calculated Risk', 'Fairway First'],
          confidenceScore: confidence,
          lastUpdated:     now,
        );
      case PlayStyleType.consistentPlayer:
        return PlayStyleIdentity(
          type:            type,
          title:           'Consistent Player',
          description:     'Predictability is your superpower. You rarely blow up a hole, and your scorecard looks almost the same every time out.',
          traits:          ['Low Variance', 'Bogey Avoider', 'Reliable Iron Play', 'Mental Fortitude'],
          confidenceScore: confidence,
          lastUpdated:     now,
        );
      case PlayStyleType.shortGameMaster:
        return PlayStyleIdentity(
          type:            type,
          title:           'Short Game Master',
          description:     'The magic happens within 100 yards. Your putting and chipping rescue holes others would bogey, making you deadly from anywhere near the pin.',
          traits:          ['Elite Putter', 'Scrambling Expert', 'Up & Down', 'Green Reader'],
          confidenceScore: confidence,
          lastUpdated:     now,
        );
      case PlayStyleType.safePlayer:
        return PlayStyleIdentity(
          type:            type,
          title:           'Safe Player',
          description:     'You play within yourself. Fairways, greens, and two-putts. Minimal risk, minimal drama — your game is built on not beating yourself.',
          traits:          ['Conservative', 'Fairway Seeker', 'Par Hunter', 'Error Avoider'],
          confidenceScore: confidence,
          lastUpdated:     now,
        );
      case PlayStyleType.weekendGolfer:
        return PlayStyleIdentity(
          type:            type,
          title:           'Weekend Golfer',
          description:     'You\'re out here for the love of the game. Play more rounds and your personalised Play Style will unlock based on real performance data.',
          traits:          ['Fun First', 'Social Game', 'Always Improving', 'Love the Outdoors'],
          confidenceScore: confidence,
          lastUpdated:     now,
        );
    }
  }
}
