import '../models/golf_dna.dart';
import '../models/round.dart';
import 'stats_service.dart';

class GolfDNAService {
  /// Computes a [GolfDNA] from a list of completed rounds.
  /// Pass an empty list (or call without rounds) to get a mock profile
  /// useful during development or when the user has no data yet.
  static GolfDNA compute(List<Round> rounds) {
    if (rounds.isEmpty) return _mock();

    final stats = StatsService.calculate(rounds);

    // ── Raw metric derivation ──────────────────────────────────────────────

    // Driving power: inversely correlates with score-over-par
    // A scratch golfer (0 avg diff) gets ~75; +10 avg gets ~40
    final avgDiff = stats.avgScore.clamp(-5.0, 20.0);
    final drivingPower = (75 - (avgDiff * 2.0)).round().clamp(20, 95);

    // Accuracy: fairways hit % maps 30–80 % → 20–95
    final accuracy = _pctToScore(stats.fairwaysHitPct, min: 30, max: 80);

    // Putting: avg putts per hole maps 1.5–2.5 → 95–20 (lower = better)
    final avgPuttsNorm = ((stats.avgPutts - 1.5) / 1.0).clamp(0.0, 1.0);
    final putting = (95 - (avgPuttsNorm * 75)).round().clamp(20, 95);

    // Consistency: GIR % maps 20–75 % → 20–95
    final consistency = _pctToScore(stats.girPct, min: 20, max: 75);

    // Risk level: birdies per round × 10, scaled 0–80
    final birdiesPerRound = rounds.isEmpty
        ? 0.0
        : stats.totalBirdies / rounds.length;
    final riskLevel = (birdiesPerRound * 10).round().clamp(5, 80);

    // Stamina: rounds played count, asymptotic toward 90
    final stamina = (90 * (1 - (1 / (1 + stats.totalRounds * 0.15)))).round().clamp(10, 90);

    // ── Player type ────────────────────────────────────────────────────────
    final playerType = _classifyPlayer(
      drivingPower: drivingPower,
      accuracy: accuracy,
      putting: putting,
      consistency: consistency,
      riskLevel: riskLevel,
    );

    // ── Strengths / weaknesses ─────────────────────────────────────────────
    final traits = <String, int>{
      'Driving Power': drivingPower,
      'Accuracy': accuracy,
      'Putting': putting,
      'Consistency': consistency,
      'Risk Taking': riskLevel,
      'Stamina': stamina,
    };

    final sorted = traits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strengths = sorted.take(2).map(_traitToStrength).toList();
    final weaknesses = sorted.reversed.take(2).map(_traitToWeakness).toList();

    // ── Trends ────────────────────────────────────────────────────────────
    final trends = _buildTrends(rounds, stats);

    return GolfDNA(
      playerType: playerType,
      summary: _buildSummary(playerType, drivingPower, accuracy, putting),
      drivingPower: drivingPower,
      accuracy: accuracy,
      putting: putting,
      consistency: consistency,
      riskLevel: riskLevel,
      stamina: stamina,
      strengths: strengths,
      weaknesses: weaknesses,
      trends: trends,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _pctToScore(double pct, {required double min, required double max}) {
    final norm = ((pct - min) / (max - min)).clamp(0.0, 1.0);
    return (20 + norm * 75).round().clamp(20, 95);
  }

  static String _classifyPlayer({
    required int drivingPower,
    required int accuracy,
    required int putting,
    required int consistency,
    required int riskLevel,
  }) {
    if (drivingPower >= 70 && riskLevel >= 55) return 'Aggressive Striker';
    if (consistency >= 70 && accuracy >= 65)   return 'Precision Player';
    if (putting >= 70 && consistency >= 60)     return 'Short Game Maestro';
    if (drivingPower >= 65 && accuracy >= 60)   return 'Power Accurate';
    if (consistency >= 65)                      return 'Steady Performer';
    if (putting >= 65)                          return 'Putting Specialist';
    if (riskLevel >= 60)                        return 'Risk Taker';
    return 'All-Round Golfer';
  }

  static String _buildSummary(String type, int drive, int acc, int putt) {
    switch (type) {
      case 'Aggressive Striker':
        return 'You attack the course with power and boldness. Your long game is your biggest weapon — embrace it and trust your short game to close out holes.';
      case 'Precision Player':
        return 'Your fairways and greens percentage is elite. You win rounds by avoiding mistakes and hitting targets consistently.';
      case 'Short Game Maestro':
        return 'You save par when others can\'t. Your scrambling and putting ability make you dangerous even when the long game goes sideways.';
      case 'Power Accurate':
        return 'Rare combination — you hit it far AND straight. Your ball-striking is a genuine competitive advantage.';
      case 'Steady Performer':
        return 'You rarely blow up a round. Bogey-free golf is your calling card; one more scoring zone and you\'ll be unstoppable.';
      case 'Putting Specialist':
        return 'You make everything inside 15 feet. Your ability to convert pressure putts keeps your scorecard clean.';
      case 'Risk Taker':
        return 'Eagles and doubles live on the same card for you. Channelling your aggression on the right holes could unlock your best rounds yet.';
      default:
        return 'You bring a balanced, well-rounded game to the course every time out. Small improvements across each category will unlock a new level.';
    }
  }

  static String _traitToStrength(MapEntry<String, int> e) {
    switch (e.key) {
      case 'Driving Power':  return 'Long off the tee — gains distance advantage on par 5s';
      case 'Accuracy':       return 'Consistent ball-striking keeps you on short grass';
      case 'Putting':        return 'Deadly on the greens — rarely three-putts';
      case 'Consistency':    return 'Rarely makes unforced errors; bogey-free rounds are common';
      case 'Risk Taking':    return 'Aggressive play style produces scoring opportunities';
      case 'Stamina':        return 'Strong back-nine finishes show great endurance';
      default:               return e.key;
    }
  }

  static String _traitToWeakness(MapEntry<String, int> e) {
    switch (e.key) {
      case 'Driving Power':  return 'Distance off the tee could unlock shorter approach shots';
      case 'Accuracy':       return 'Fairway % needs work — missed fairways add up quickly';
      case 'Putting':        return 'Putting under pressure is costing shots per round';
      case 'Consistency':    return 'Occasional blow-up holes inflate the scorecard';
      case 'Risk Taking':    return 'More conservative play could lower overall score';
      case 'Stamina':        return 'Back-nine scores suggest fitness or focus can improve';
      default:               return e.key;
    }
  }

  static List<String> _buildTrends(List<Round> rounds, AppStats stats) {
    final trends = <String>[];
    if (rounds.length >= 3) {
      final recent = rounds.take(3).toList();
      final earlier = rounds.skip(3).take(3).toList();
      if (earlier.isNotEmpty) {
        final recentAvg = recent.fold(0.0, (s, r) => s + r.scoreDiff) / recent.length;
        final earlierAvg = earlier.fold(0.0, (s, r) => s + r.scoreDiff) / earlier.length;
        if (recentAvg < earlierAvg - 1) {
          trends.add('Scoring improving — your last 3 rounds average ${recentAvg.toStringAsFixed(1)} vs par');
        } else if (recentAvg > earlierAvg + 1) {
          trends.add('Slight scoring uptick recently — revisit your pre-round warmup');
        }
      }
    }
    if (stats.avgPutts < 1.8) {
      trends.add('Putting is a consistent strength — average ${stats.avgPutts.toStringAsFixed(1)} putts/hole');
    } else if (stats.avgPutts > 2.1) {
      trends.add('Reducing putts per hole from ${stats.avgPutts.toStringAsFixed(1)} to under 2.0 could save ${((stats.avgPutts - 2.0) * 18).round()} shots per round');
    }
    if (stats.girPct > 50) {
      trends.add('Greens in regulation above 50% — your iron game is tour-level consistent');
    } else if (stats.girPct < 25) {
      trends.add('Improving GIR from ${stats.girPct.round()}% to 40% would be a game-changer');
    }
    if (stats.totalBirdies > stats.totalRounds) {
      trends.add('Averaging more than one birdie per round — keep attacking pins');
    }
    if (trends.isEmpty) {
      trends.add('Play more rounds to unlock personalised trend insights');
    }
    return trends;
  }

  // ── Mock profile (no data) ────────────────────────────────────────────────
  static GolfDNA _mock() => const GolfDNA(
        playerType: 'All-Round Golfer',
        summary: 'Play a few rounds and your Golf DNA will be calculated from your actual performance data.',
        drivingPower: 62,
        accuracy: 55,
        putting: 68,
        consistency: 58,
        riskLevel: 45,
        stamina: 50,
        strengths: [
          'Strong putting keeps scores competitive',
          'Consistent ball-striking minimises big numbers',
        ],
        weaknesses: [
          'Distance off the tee could unlock better approach angles',
          'GIR % has room to grow with targeted iron practice',
        ],
        trends: [
          'Play more rounds to unlock personalised trend insights',
        ],
      );
}
