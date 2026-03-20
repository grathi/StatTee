import '../models/round.dart';
import '../services/stats_service.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final bool Function(AppStats, List<Round>) condition;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.condition,
  });
}

class AchievementService {
  static final List<Achievement> all = [
    Achievement(
      id: 'first_round',
      name: 'Tee Off',
      description: 'Complete your first round',
      emoji: '⛳',
      condition: (s, _) => s.totalRounds >= 1,
    ),
    Achievement(
      id: 'first_birdie',
      name: 'First Birdie',
      description: 'Score your first birdie',
      emoji: '🐦',
      condition: (s, _) => s.totalBirdies >= 1,
    ),
    Achievement(
      id: 'under_par',
      name: 'Under Par',
      description: 'Finish a round under par',
      emoji: '🟢',
      condition: (_, rounds) => rounds.any((r) => r.scores.isNotEmpty && r.scoreDiff < 0),
    ),
    Achievement(
      id: 'eagle_club',
      name: 'Eagle Club',
      description: 'Score an eagle or better',
      emoji: '🦅',
      condition: (_, rounds) => rounds.any((r) => r.eagles > 0),
    ),
    Achievement(
      id: 'scratch_round',
      name: 'Scratch Round',
      description: 'Finish a round exactly at par',
      emoji: '💎',
      condition: (_, rounds) => rounds.any((r) => r.scores.isNotEmpty && r.scoreDiff == 0),
    ),
    Achievement(
      id: 'birdie_machine',
      name: 'Birdie Machine',
      description: 'Accumulate 10 total birdies',
      emoji: '⭐',
      condition: (s, _) => s.totalBirdies >= 10,
    ),
    Achievement(
      id: 'fairway_finder',
      name: 'Fairway Finder',
      description: 'Hit 60% of fairways on average',
      emoji: '🎯',
      condition: (s, _) => s.totalRounds >= 3 && s.fairwaysHitPct >= 60,
    ),
    Achievement(
      id: 'gir_master',
      name: 'GIR Master',
      description: 'Hit 50% of greens in regulation on average',
      emoji: '🌿',
      condition: (s, _) => s.totalRounds >= 3 && s.girPct >= 50,
    ),
    Achievement(
      id: 'iron_putter',
      name: 'Iron Putter',
      description: 'Average under 1.8 putts per hole',
      emoji: '🏆',
      condition: (s, _) => s.totalRounds >= 3 && s.avgPutts > 0 && s.avgPutts < 1.8,
    ),
    Achievement(
      id: 'hot_streak',
      name: 'Hot Streak',
      description: 'Score under par in 3 consecutive rounds',
      emoji: '🔥',
      condition: (_, rounds) => _hasConsecutiveUnderPar(rounds, 3),
    ),
    Achievement(
      id: 'ten_rounds',
      name: 'Veteran',
      description: 'Complete 10 rounds',
      emoji: '🥉',
      condition: (s, _) => s.totalRounds >= 10,
    ),
    Achievement(
      id: 'centurion',
      name: 'Century Club',
      description: 'Complete 100 rounds',
      emoji: '💯',
      condition: (s, _) => s.totalRounds >= 100,
    ),
  ];

  /// Returns the list of achievements the user has unlocked.
  static List<Achievement> evaluate(AppStats stats, List<Round> rounds) {
    return all.where((a) => a.condition(stats, rounds)).toList();
  }

  static bool _hasConsecutiveUnderPar(List<Round> rounds, int count) {
    // rounds are sorted newest-first; check any consecutive window
    int streak = 0;
    for (final r in rounds) {
      if (r.scores.isNotEmpty && r.scoreDiff < 0) {
        streak++;
        if (streak >= count) return true;
      } else {
        streak = 0;
      }
    }
    return false;
  }
}
