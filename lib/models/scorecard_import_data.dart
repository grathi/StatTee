class ImportedHole {
  final int hole; // 1-indexed
  int par;        // 3, 4, or 5
  int score;      // 0 = unreadable (highlighted red in review UI)

  ImportedHole({required this.hole, required this.par, required this.score});
}

class PlayerImportData {
  String playerName;          // "" = unnamed (editable in UI)
  List<ImportedHole> holes;

  PlayerImportData({required this.playerName, required this.holes});

  int get totalPar   => holes.fold(0, (s, h) => s + h.par);
  int get totalScore => holes.fold(0, (s, h) => s + h.score);
  int get scoreDiff  => totalScore - totalPar;
  bool get hasUnreadableScores => holes.any((h) => h.score == 0);
}

class ScorecardImportData {
  String courseName;
  String courseLocation;
  int totalHoles; // 9 or 18
  List<PlayerImportData> players; // 1–4 players
  DateTime roundDate;
  double? courseRating;
  int? slopeRating;
  String? warningMessage; // Gemini warnings or hole-count issues

  ScorecardImportData({
    required this.courseName,
    required this.courseLocation,
    required this.totalHoles,
    required this.players,
    required this.roundDate,
    this.courseRating,
    this.slopeRating,
    this.warningMessage,
  });

  /// Convenience accessor — holes for the first (primary) player.
  List<ImportedHole> get holes => players.first.holes;

  int get totalPar   => holes.fold(0, (s, h) => s + h.par);
  int get totalScore => holes.fold(0, (s, h) => s + h.score);
  int get scoreDiff  => totalScore - totalPar;
  bool get hasUnreadableScores => players.any((p) => p.hasUnreadableScores);
}
