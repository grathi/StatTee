class RoundStrategyBrief {
  final String headline;
  final String strategy;
  final String keyFocus;
  final List<HoleTypeCoachingTip> holeCoachingTips;
  final String putterReminder;
  final String confidenceBoost;

  const RoundStrategyBrief({
    required this.headline,
    required this.strategy,
    required this.keyFocus,
    required this.holeCoachingTips,
    required this.putterReminder,
    required this.confidenceBoost,
  });

  factory RoundStrategyBrief.fromJson(Map<String, dynamic> j) =>
      RoundStrategyBrief(
        headline: j['headline'] as String? ?? '',
        strategy: j['strategy'] as String? ?? '',
        keyFocus: j['keyFocus'] as String? ?? '',
        holeCoachingTips: (j['holeCoachingTips'] as List<dynamic>?)
                ?.map((t) => HoleTypeCoachingTip.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        putterReminder: j['putterReminder'] as String? ?? '',
        confidenceBoost: j['confidenceBoost'] as String? ?? '',
      );
}

class HoleTypeCoachingTip {
  final String parType;
  final String tip;

  const HoleTypeCoachingTip({required this.parType, required this.tip});

  factory HoleTypeCoachingTip.fromJson(Map<String, dynamic> j) =>
      HoleTypeCoachingTip(
        parType: j['parType'] as String? ?? '',
        tip: j['tip'] as String? ?? '',
      );
}
