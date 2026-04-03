import 'shot_position.dart';

class HoleScore {
  final int hole;
  final int par;
  final int score;
  final int putts;
  final bool fairwayHit; // meaningful only on par 4/5
  final bool gir;        // greens in regulation
  final String? club;    // club used on the tee/approach shot
  final List<ShotPosition>? shots; // GPS shot trail (optional)

  const HoleScore({
    required this.hole,
    required this.par,
    required this.score,
    required this.putts,
    required this.fairwayHit,
    required this.gir,
    this.club,
    this.shots,
  });

  int get diff => score - par;
  bool get isEagleOrBetter => diff <= -2;
  bool get isBirdie => diff == -1;
  bool get isPar => diff == 0;
  bool get isBogey => diff == 1;
  bool get isDoublePlus => diff >= 2;

  Map<String, dynamic> toMap() => {
        'hole': hole,
        'par': par,
        'score': score,
        'putts': putts,
        'fairwayHit': fairwayHit,
        'gir': gir,
        if (club != null) 'club': club,
        if (shots != null && shots!.isNotEmpty)
          'shots': shots!.map((s) => s.toMap()).toList(),
      };

  factory HoleScore.fromMap(Map<String, dynamic> m) => HoleScore(
        hole: (m['hole'] as num).toInt(),
        par: (m['par'] as num).toInt(),
        score: (m['score'] as num).toInt(),
        putts: (m['putts'] as num).toInt(),
        fairwayHit: m['fairwayHit'] as bool? ?? false,
        gir: m['gir'] as bool? ?? false,
        club: m['club'] as String?,
        shots: (m['shots'] as List<dynamic>?)
            ?.map((e) => ShotPosition.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}

