class CourseHole {
  final int hole;
  final int par;
  final int yardage;
  final int handicap;

  const CourseHole({
    required this.hole,
    required this.par,
    required this.yardage,
    required this.handicap,
  });

  factory CourseHole.fromJson(Map<String, dynamic> j) => CourseHole(
        hole:     (j['hole']     as num).toInt(),
        par:      (j['par']      as num).toInt(),
        yardage:  (j['yardage']  as num).toInt(),
        handicap: (j['handicap'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'hole':     hole,
        'par':      par,
        'yardage':  yardage,
        'handicap': handicap,
      };
}

class CourseTee {
  final String name;
  final double courseRating;
  final int    slopeRating;
  final List<CourseHole> holes;

  const CourseTee({
    required this.name,
    required this.courseRating,
    required this.slopeRating,
    required this.holes,
  });

  /// True when 18 hole entries are the front 9 duplicated into the back 9.
  /// Checks both par AND yardage — if both match for all 9 pairs it's a
  /// 9-hole course whose scorecard repeats the layout for the back 9.
  bool get isDuplicated9Hole {
    if (holes.length != 18) return false;
    for (var i = 0; i < 9; i++) {
      if (holes[i].par     != holes[i + 9].par)     return false;
      if (holes[i].yardage != holes[i + 9].yardage) return false;
    }
    return true;
  }

  /// The effective hole list to use during scoring:
  /// front 9 only when the data is a duplicated 9-hole layout.
  List<CourseHole> get effectiveHoles =>
      isDuplicated9Hole ? holes.take(9).toList() : holes;

  int get holeCount => effectiveHoles.length;

  factory CourseTee.fromJson(Map<String, dynamic> j) => CourseTee(
        name:         j['name'] as String? ?? '',
        courseRating: (j['courseRating'] as num?)?.toDouble() ?? 0.0,
        slopeRating:  (j['slopeRating']  as num?)?.toInt()    ?? 0,
        holes: (j['holes'] as List<dynamic>? ?? [])
            .map((h) => CourseHole.fromJson(h as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name':         name,
        'courseRating': courseRating,
        'slopeRating':  slopeRating,
        'holes':        holes.map((h) => h.toJson()).toList(),
      };
}

class CourseData {
  final String id;
  final String name;
  final String location;
  final List<CourseTee> tees;

  const CourseData({
    required this.id,
    required this.name,
    required this.location,
    required this.tees,
  });

  factory CourseData.fromJson(String id, Map<String, dynamic> j) => CourseData(
        id:       id,
        name:     j['name']     as String? ?? '',
        location: j['location'] as String? ?? '',
        tees: (j['tees'] as List<dynamic>? ?? [])
            .map((t) => CourseTee.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name':     name,
        'location': location,
        'tees':     tees.map((t) => t.toJson()).toList(),
      };
}
