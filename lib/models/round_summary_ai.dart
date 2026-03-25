class RoundSummaryAI {
  final String headline;
  final String summary;
  final String strength;
  final String weakness;
  final String focusArea;
  final int? calories;

  const RoundSummaryAI({
    required this.headline,
    required this.summary,
    required this.strength,
    required this.weakness,
    required this.focusArea,
    this.calories,
  });

  factory RoundSummaryAI.fromJson(Map<String, dynamic> json) => RoundSummaryAI(
        headline:  json['headline']  as String? ?? '',
        summary:   json['summary']   as String? ?? '',
        strength:  json['strength']  as String? ?? '',
        weakness:  json['weakness']  as String? ?? '',
        focusArea: json['focusArea'] as String? ?? '',
        calories:  json['calories']  as int?,
      );
}
