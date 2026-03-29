class ImportedHole {
  final int hole; // 1-indexed
  int par;        // 3, 4, or 5
  int score;      // 0 = unreadable (highlighted red in review UI)

  ImportedHole({required this.hole, required this.par, required this.score});
}

class ScorecardImportData {
  String courseName;
  String courseLocation;
  int totalHoles; // 9 or 18
  List<ImportedHole> holes;
  DateTime roundDate;
  double? courseRating;
  int? slopeRating;
  String? warningMessage; // Gemini warnings or hole-count issues

  ScorecardImportData({
    required this.courseName,
    required this.courseLocation,
    required this.totalHoles,
    required this.holes,
    required this.roundDate,
    this.courseRating,
    this.slopeRating,
    this.warningMessage,
  });

  int get totalPar   => holes.fold(0, (s, h) => s + h.par);
  int get totalScore => holes.fold(0, (s, h) => s + h.score);
  int get scoreDiff  => totalScore - totalPar;
  bool get hasUnreadableScores => holes.any((h) => h.score == 0);
}
