import 'package:cloud_firestore/cloud_firestore.dart';
import 'hole_score.dart';
import '../services/weather_service.dart';

enum RoundStatus { active, completed }

class Round {
  final String? id;
  final String userId;
  final String courseName;
  final String courseLocation;
  final int totalHoles; // 9 or 18
  final RoundStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<HoleScore> scores;
  final double? courseRating;  // USGA course rating e.g. 72.5
  final int? slopeRating;      // USGA slope rating e.g. 135
  final WeatherData? weather;  // Conditions at round start
  final bool isPractice;       // true = practice round (hidden from Rounds tab)
  final String? tournamentId;  // set when started from Tournament tab
  /// The hole the user was on when they last left the round (1-indexed).
  /// Used to resume from the correct position.
  final int currentHole;
  /// Course coordinates — persisted so the shot tracker can centre on the
  /// course when a round is resumed (not just when first started).
  final double? lat;
  final double? lng;
  /// Group round session this round belongs to. Null for solo rounds.
  final String? sessionId;
  /// Name of a companion player imported alongside the current user.
  /// Null for the current user's own rounds.
  final String? playerName;

  const Round({
    this.id,
    required this.userId,
    required this.courseName,
    required this.courseLocation,
    required this.totalHoles,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.scores = const [],
    this.courseRating,
    this.slopeRating,
    this.weather,
    this.isPractice = false,
    this.tournamentId,
    this.currentHole = 1,
    this.lat,
    this.lng,
    this.sessionId,
    this.playerName,
  });

  // ── Computed stats ──────────────────────────────────────────────────────

  int get holesPlayed => scores.length;
  bool get isComplete => status == RoundStatus.completed;

  int get totalScore => scores.fold(0, (s, h) => s + h.score);
  int get totalPar   => scores.fold(0, (s, h) => s + h.par);
  int get scoreDiff  => totalScore - totalPar;

  String get scoreDiffLabel =>
      scoreDiff == 0 ? 'E' : scoreDiff > 0 ? '+$scoreDiff' : '$scoreDiff';

  int get totalPutts => scores.fold(0, (s, h) => s + h.putts);
  double get avgPutts =>
      scores.isEmpty ? 0.0 : totalPutts / scores.length;

  /// Fairways Hit % — only counts par 4 & par 5 holes
  double get fairwaysHitPct {
    final eligible = scores.where((h) => h.par >= 4).toList();
    if (eligible.isEmpty) return 0.0;
    return eligible.where((h) => h.fairwayHit).length / eligible.length * 100;
  }

  /// GIR % — greens in regulation
  double get girPct {
    if (scores.isEmpty) return 0.0;
    return scores.where((h) => h.gir).length / scores.length * 100;
  }

  int get birdies    => scores.where((h) => h.isBirdie).length;
  int get eagles     => scores.where((h) => h.isEagleOrBetter).length;
  int get pars       => scores.where((h) => h.isPar).length;
  int get bogeys     => scores.where((h) => h.isBogey).length;
  int get doublePlus => scores.where((h) => h.isDoublePlus).length;

  /// Score differential — uses USGA formula when course rating & slope are available.
  double get scoreDifferential {
    if (courseRating != null && slopeRating != null && slopeRating! > 0) {
      return (totalScore - courseRating!) * 113 / slopeRating!;
    }
    return scoreDiff.toDouble();
  }

  // ── Firestore serialisation ─────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'courseName': courseName,
        'courseLocation': courseLocation,
        'totalHoles': totalHoles,
        'status': status.name,
        'startedAt': Timestamp.fromDate(startedAt),
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        'scores': scores.map((h) => h.toMap()).toList(),
        if (courseRating != null) 'courseRating': courseRating,
        if (slopeRating != null) 'slopeRating': slopeRating,
        if (weather != null) 'weather': weather!.toMap(),
        if (isPractice) 'isPractice': true,
        if (tournamentId != null) 'tournamentId': tournamentId,
        'currentHole': currentHole,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (sessionId != null) 'sessionId': sessionId,
        if (playerName != null) 'playerName': playerName,
      };

  factory Round.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Round(
      id: doc.id,
      userId: d['userId'] as String,
      courseName: d['courseName'] as String,
      courseLocation: d['courseLocation'] as String? ?? '',
      totalHoles: (d['totalHoles'] as num).toInt(),
      status: RoundStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => RoundStatus.active,
      ),
      startedAt: (d['startedAt'] as Timestamp).toDate(),
      completedAt: d['completedAt'] != null
          ? (d['completedAt'] as Timestamp).toDate()
          : null,
      scores: (d['scores'] as List<dynamic>? ?? [])
          .map((e) => HoleScore.fromMap(e as Map<String, dynamic>))
          .toList(),
      courseRating: (d['courseRating'] as num?)?.toDouble(),
      slopeRating: (d['slopeRating'] as num?)?.toInt(),
      weather: d['weather'] != null
          ? WeatherData.fromMap(d['weather'] as Map<String, dynamic>)
          : null,
      isPractice: (d['isPractice'] as bool?) ?? false,
      tournamentId: d['tournamentId'] as String?,
      currentHole: (d['currentHole'] as num?)?.toInt() ?? 1,
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      sessionId: d['sessionId'] as String?,
      playerName: d['playerName'] as String?,
    );
  }

  Round copyWith({
    String? id,
    RoundStatus? status,
    DateTime? completedAt,
    List<HoleScore>? scores,
    double? courseRating,
    int? slopeRating,
    WeatherData? weather,
    bool? isPractice,
    String? tournamentId,
    int? currentHole,
    double? lat,
    double? lng,
    String? sessionId,
    String? playerName,
  }) =>
      Round(
        id: id ?? this.id,
        userId: userId,
        courseName: courseName,
        courseLocation: courseLocation,
        totalHoles: totalHoles,
        status: status ?? this.status,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
        scores: scores ?? this.scores,
        courseRating: courseRating ?? this.courseRating,
        slopeRating: slopeRating ?? this.slopeRating,
        weather: weather ?? this.weather,
        isPractice: isPractice ?? this.isPractice,
        tournamentId: tournamentId ?? this.tournamentId,
        currentHole: currentHole ?? this.currentHole,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        sessionId: sessionId ?? this.sessionId,
        playerName: playerName ?? this.playerName,
      );
}
