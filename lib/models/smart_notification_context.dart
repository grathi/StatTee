// ---------------------------------------------------------------------------
// UserActivityData — captures recent user behaviour fed into the rule engine
// ---------------------------------------------------------------------------
class UserActivityData {
  /// ID of any currently active (incomplete) round. Null if none.
  final String? activeRoundId;

  /// Course name of the active round, if any.
  final String? activeRoundCourse;

  /// How many holes have been completed in the active round.
  final int activeRoundHolesPlayed;

  /// Total holes in the active round (9 or 18).
  final int activeRoundTotalHoles;

  /// When the active round was last updated (last hole saved).
  final DateTime? activeRoundLastUpdated;

  /// Date of the most recently completed round.
  final DateTime? lastCompletedRoundDate;

  /// Total completed rounds (all time).
  final int totalRoundsCompleted;

  /// Days since the last completed round. Null if never played.
  final int? daysSinceLastRound;

  const UserActivityData({
    this.activeRoundId,
    this.activeRoundCourse,
    this.activeRoundHolesPlayed = 0,
    this.activeRoundTotalHoles  = 18,
    this.activeRoundLastUpdated,
    this.lastCompletedRoundDate,
    this.totalRoundsCompleted = 0,
    this.daysSinceLastRound,
  });

  bool get hasIncompleteRound =>
      activeRoundId != null && activeRoundHolesPlayed > 0;

  bool get isNewUser => totalRoundsCompleted == 0;
}

// ---------------------------------------------------------------------------
// WeaknessArea — identified weak stat category
// ---------------------------------------------------------------------------
enum WeaknessArea { putting, approach, driving, shortGame, courseManagement }

extension WeaknessAreaX on WeaknessArea {
  String get label {
    switch (this) {
      case WeaknessArea.putting:           return 'Putting';
      case WeaknessArea.approach:          return 'Approach Shots';
      case WeaknessArea.driving:           return 'Driving';
      case WeaknessArea.shortGame:         return 'Short Game';
      case WeaknessArea.courseManagement:  return 'Course Management';
    }
  }

  String get drillHint {
    switch (this) {
      case WeaknessArea.putting:
        return 'Spend 10 min on lag putts from 20+ feet.';
      case WeaknessArea.approach:
        return 'Focus on landing zone — aim for the fat part of the green.';
      case WeaknessArea.driving:
        return 'Work on your pre-shot routine off the tee for consistency.';
      case WeaknessArea.shortGame:
        return 'Practice 30-60 yard wedge shots with varying trajectories.';
      case WeaknessArea.courseManagement:
        return 'Before each shot, pick a conservative target and commit.';
    }
  }
}

// ---------------------------------------------------------------------------
// PerformanceTrendData — rolling stats from recent rounds
// ---------------------------------------------------------------------------
class PerformanceTrendData {
  /// Number of completed rounds analysed (typically last 5–10).
  final int roundsAnalysed;

  /// Average score-vs-par across analysed rounds.
  final double avgScoreDiff;

  /// Score difference from the previous period (negative = improving).
  final double? trendDelta;

  /// Average putts per hole.
  final double avgPuttsPerHole;

  /// Average GIR percentage (0–100).
  final double avgGirPct;

  /// Average fairways hit percentage (0–100).
  final double avgFairwaysPct;

  /// Identified primary weakness area.
  final WeaknessArea? primaryWeakness;

  /// True if the last N rounds show consistent score improvement.
  final bool isImproving;

  /// How many strokes improvement over the analysed window.
  final double? improvementStrokes;

  const PerformanceTrendData({
    required this.roundsAnalysed,
    required this.avgScoreDiff,
    this.trendDelta,
    required this.avgPuttsPerHole,
    required this.avgGirPct,
    required this.avgFairwaysPct,
    this.primaryWeakness,
    this.isImproving = false,
    this.improvementStrokes,
  });

  bool get hasEnoughData => roundsAnalysed >= 1;

  /// Derives weakness from aggregated stats when not explicitly set.
  WeaknessArea get effectiveWeakness {
    if (primaryWeakness != null) return primaryWeakness!;
    if (avgPuttsPerHole > 2.0) return WeaknessArea.putting;
    if (avgGirPct < 35)        return WeaknessArea.approach;
    if (avgFairwaysPct < 50)   return WeaknessArea.driving;
    return WeaknessArea.shortGame;
  }
}

// ---------------------------------------------------------------------------
// TeeTimeData — upcoming scheduled tee time
// ---------------------------------------------------------------------------
class TeeTimeData {
  final String id;
  final String courseName;
  final String? courseLocation;
  final DateTime scheduledAt;
  final int? numberOfPlayers;
  final String? notes;

  const TeeTimeData({
    required this.id,
    required this.courseName,
    this.courseLocation,
    required this.scheduledAt,
    this.numberOfPlayers,
    this.notes,
  });

  Duration get timeUntil => scheduledAt.difference(DateTime.now());

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return scheduledAt.year == tomorrow.year &&
        scheduledAt.month == tomorrow.month &&
        scheduledAt.day == tomorrow.day;
  }

  bool get isWithinReminderWindow {
    final diff = timeUntil;
    return diff.inMinutes >= 30 && diff.inHours <= 24;
  }

  Map<String, dynamic> toMap() => {
        'id':             id,
        'courseName':     courseName,
        'courseLocation': courseLocation,
        'scheduledAt':    scheduledAt.toIso8601String(),
        'numberOfPlayers': numberOfPlayers,
        'notes':          notes,
      };

  factory TeeTimeData.fromMap(Map<String, dynamic> map) => TeeTimeData(
        id:              map['id'] as String,
        courseName:      map['courseName'] as String,
        courseLocation:  map['courseLocation'] as String?,
        scheduledAt:     DateTime.parse(map['scheduledAt'] as String),
        numberOfPlayers: map['numberOfPlayers'] as int?,
        notes:           map['notes'] as String?,
      );
}

// ---------------------------------------------------------------------------
// SmartNotificationContext — full context snapshot passed to the service
// ---------------------------------------------------------------------------
class SmartNotificationContext {
  final UserActivityData activity;
  final PerformanceTrendData performance;
  final List<TeeTimeData> upcomingTeeTimes;
  final Map<String, bool> userPreferences;

  const SmartNotificationContext({
    required this.activity,
    required this.performance,
    required this.upcomingTeeTimes,
    this.userPreferences = const {},
  });

  bool preferenceFor(String key) => userPreferences[key] ?? true;
}
