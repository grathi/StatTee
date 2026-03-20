import '../models/round.dart';

class AppStats {
  final double handicapIndex;
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
    handicapIndex: 0,
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

  String get handicapLabel => handicapIndex.toStringAsFixed(1);
}

class StatsService {
  /// Calculates all stats from a list of completed rounds.
  static AppStats calculate(List<Round> rounds) {
    if (rounds.isEmpty) return AppStats.empty;

    // Only full 18-hole rounds for handicap calc
    final full = rounds.where((r) => r.totalHoles == 18 && r.scores.length == 18).toList();
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

    // Handicap Index — avg of score differentials from best 8 of last 20
    final diffs = full.take(20).map((r) => r.scoreDifferential).toList()
      ..sort();
    final best8 = diffs.take(8).toList();
    final handicap = best8.isEmpty
        ? avgDiff.clamp(0.0, 54.0)
        : (best8.fold(0.0, (s, d) => s + d) / best8.length).clamp(0.0, 54.0);

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
