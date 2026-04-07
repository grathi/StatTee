class MetricInsight {
  final String metricId;
  final String insight;
  final String drill;

  const MetricInsight({
    required this.metricId,
    required this.insight,
    required this.drill,
  });

  factory MetricInsight.fromJson(Map<String, dynamic> j) => MetricInsight(
        metricId: j['metricId'] as String? ?? '',
        insight:  j['insight']  as String? ?? '',
        drill:    j['drill']    as String? ?? '',
      );
}

class PressureNarrative {
  final String headline;
  final String overallInsight;
  final List<MetricInsight> metricInsights;
  final String topDrill;

  const PressureNarrative({
    required this.headline,
    required this.overallInsight,
    required this.metricInsights,
    required this.topDrill,
  });

  factory PressureNarrative.fromJson(Map<String, dynamic> j) => PressureNarrative(
        headline:       j['headline']       as String? ?? '',
        overallInsight: j['overallInsight'] as String? ?? '',
        topDrill:       j['topDrill']       as String? ?? '',
        metricInsights: (j['metricInsights'] as List<dynamic>? ?? [])
            .map((e) => MetricInsight.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Fallback returned when the Gemini call fails entirely.
  const PressureNarrative.fallback()
      : headline       = 'Keep playing to reveal your pressure patterns',
        overallInsight = 'Play more rounds for a detailed mental game analysis.',
        metricInsights = const [],
        topDrill       = '';

  MetricInsight? insightFor(String metricId) {
    try {
      return metricInsights.firstWhere((m) => m.metricId == metricId);
    } catch (_) {
      return null;
    }
  }
}
