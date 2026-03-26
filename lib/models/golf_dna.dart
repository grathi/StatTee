class GolfDNA {
  final String playerType;
  final String summary;
  final int drivingPower;    // 0–100
  final int accuracy;        // 0–100
  final int putting;         // 0–100
  final int consistency;     // 0–100
  final int riskLevel;       // 0–100
  final int stamina;         // 0–100
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> trends;

  const GolfDNA({
    required this.playerType,
    required this.summary,
    required this.drivingPower,
    required this.accuracy,
    required this.putting,
    required this.consistency,
    required this.riskLevel,
    required this.stamina,
    required this.strengths,
    required this.weaknesses,
    required this.trends,
  });
}
