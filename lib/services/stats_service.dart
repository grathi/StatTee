import '../models/round.dart';

class AppStats {
  final double? handicapIndex;  // null until 20 full rounds completed (WHS)
  final double avgScore;       // avg score diff vs par
  final int bestRoundScore;    // lowest total score
  final int totalRounds;
  final double fairwaysHitPct;
  final double girPct;
  final double avgPutts;
  final int totalBirdies;

  const AppStats({
    required this.handicapIndex,
    required this.avgScore,
    required this.bestRoundScore,
    required this.totalRounds,
    required this.fairwaysHitPct,
    required this.girPct,
    required this.avgPutts,
    required this.totalBirdies,
  });

  static const empty = AppStats(
    handicapIndex: null,
    avgScore: 0,
    bestRoundScore: 0,
    totalRounds: 0,
    fairwaysHitPct: 0,
    girPct: 0,
    avgPutts: 0,
    totalBirdies: 0,
  );

  String get avgScoreLabel =>
      avgScore == 0 ? 'E' : avgScore > 0 ? '+${avgScore.toStringAsFixed(1)}' : avgScore.toStringAsFixed(1);

  String get handicapLabel {
    if (handicapIndex == null) return '-';
    return handicapIndex! <= 0
        ? '+${(-handicapIndex!).toStringAsFixed(1)}'
        : handicapIndex!.toStringAsFixed(1);
  }
}

class StatsService {
  /// Calculates all stats from a list of completed rounds.
  static AppStats calculate(List<Round> rounds) {
    if (rounds.isEmpty) return AppStats.empty;

    // All completed rounds with at least one score — used for handicap calc
    final full = rounds.where((r) => r.scores.isNotEmpty).toList();
    final all  = rounds;

    // Avg score diff
    final avgDiff = all.isEmpty
        ? 0.0
        : all.fold(0.0, (s, r) => s + r.scoreDiff) / all.length;

    // Best round — lowest totalScore on 18 holes
    final fullCompleted = full.isNotEmpty ? full : all;
    final bestScore = fullCompleted.isEmpty
        ? 0
        : fullCompleted.map((r) => r.totalScore).reduce((a, b) => a < b ? a : b);

    // Fairways hit %
    final fairways = all.isEmpty
        ? 0.0
        : all.fold(0.0, (s, r) => s + r.fairwaysHitPct) / all.length;

    // GIR %
    final gir = all.isEmpty
        ? 0.0
        : all.fold(0.0, (s, r) => s + r.girPct) / all.length;

    // Avg putts per hole
    final allPutts = all.where((r) => r.scores.isNotEmpty).toList();
    final avgPutts = allPutts.isEmpty
        ? 0.0
        : allPutts.fold(0.0, (s, r) => s + r.avgPutts) / allPutts.length;

    // Total birdies
    final birdies = all.fold(0, (s, r) => s + r.birdies);

    // Handicap Index — WHS calculation.
    // Requires minimum 3 completed rounds (18 or 9-hole treated as a pair).
    // Number of best differentials used scales with rounds played.
    final diffs = full.map((r) => r.scoreDifferential).toList()..sort();
    final n = diffs.length;
    int? bestCount;
    if      (n >= 19) bestCount = 8;
    else if (n >= 17) bestCount = 7;
    else if (n >= 15) bestCount = 6;
    else if (n >= 12) bestCount = 5;
    else if (n >= 9)  bestCount = 4;
    else if (n >= 7)  bestCount = 3;
    else if (n >= 5)  bestCount = 2;
    else if (n >= 3)  bestCount = 1;
    else if (n >= 1)  bestCount = 1;
    final best = bestCount != null ? diffs.take(bestCount).toList() : null;
    final handicap = best != null
        ? (best.fold(0.0, (s, d) => s + d) / best.length)
        : null;

    return AppStats(
      handicapIndex: handicap,
      avgScore: avgDiff,
      bestRoundScore: bestScore,
      totalRounds: all.length,
      fairwaysHitPct: fairways,
      girPct: gir,
      avgPutts: avgPutts,
      totalBirdies: birdies,
    );
  }
}
