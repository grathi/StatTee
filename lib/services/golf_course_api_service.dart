import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class GolfApiHole {
  final int hole;
  final int par;
  final int yardage;
  final int handicap;

  const GolfApiHole({
    required this.hole,
    required this.par,
    required this.yardage,
    required this.handicap,
  });

  factory GolfApiHole.fromJson(Map<String, dynamic> j, int index) => GolfApiHole(
        hole: index + 1,
        par: (j['par'] as num?)?.toInt() ?? 4,
        yardage: (j['yardage'] as num?)?.toInt() ?? 0,
        handicap: (j['handicap'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'hole': hole,
        'par': par,
        'yardage': yardage,
        'handicap': handicap,
      };
}

class GolfApiTee {
  final String name;
  final int numberOfHoles;
  final int parTotal;
  final double courseRating;
  final int slopeRating;
  final int totalYards;
  final List<GolfApiHole> holes;

  const GolfApiTee({
    required this.name,
    required this.numberOfHoles,
    required this.parTotal,
    required this.courseRating,
    required this.slopeRating,
    required this.totalYards,
    required this.holes,
  });

  factory GolfApiTee.fromJson(Map<String, dynamic> j) {
    final rawHoles = j['holes'] as List<dynamic>? ?? [];
    final holes = rawHoles
        .asMap()
        .entries
        .map((e) => GolfApiHole.fromJson(e.value as Map<String, dynamic>, e.key))
        .toList();
    return GolfApiTee(
      name: j['tee_name'] as String? ?? 'Standard',
      numberOfHoles: holes.isNotEmpty ? holes.length : (j['number_of_holes'] as num?)?.toInt() ?? 18,
      parTotal: (j['par_total'] as num?)?.toInt() ?? 72,
      courseRating: (j['course_rating'] as num?)?.toDouble() ?? 72.0,
      slopeRating: (j['slope_rating'] as num?)?.toInt() ?? 113,
      totalYards: (j['total_yards'] as num?)?.toInt() ?? 0,
      holes: holes,
    );
  }

  /// True when 18 hole entries are actually the front 9 duplicated into the back 9.
  /// Checks par only — 9-hole courses played twice intentionally use different
  /// handicap indices (odd for front, even for back), so handicap is excluded.
  bool get isDuplicated9Hole {
    if (holes.length != 18) return false;
    for (var i = 0; i < 9; i++) {
      if (holes[i].par != holes[i + 9].par) return false;
    }
    return true;
  }

  /// The effective hole list to display: front 9 only if the data is a duplicated
  /// 9-hole layout, otherwise all holes as-is.
  List<GolfApiHole> get effectiveHoles =>
      isDuplicated9Hole ? holes.take(9).toList() : holes;

  Map<String, dynamic> toJson() => {
        'tee_name': name,
        'number_of_holes': numberOfHoles,
        'par_total': parTotal,
        'course_rating': courseRating,
        'slope_rating': slopeRating,
        'total_yards': totalYards,
        'holes': holes.map((h) => h.toJson()).toList(),
      };
}

class GolfApiCourse {
  final int id;
  final String clubName;
  final String courseName;
  final String city;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;

  const GolfApiCourse({
    required this.id,
    required this.clubName,
    required this.courseName,
    required this.city,
    required this.state,
    required this.country,
    this.latitude,
    this.longitude,
  });

  String get displayName => courseName.isNotEmpty && courseName != clubName
      ? '$clubName — $courseName'
      : clubName;

  String get locationLabel {
    if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;
    return country;
  }

  factory GolfApiCourse.fromJson(Map<String, dynamic> j) {
    final loc = j['location'] as Map<String, dynamic>? ?? {};
    return GolfApiCourse(
      id: (j['id'] as num?)?.toInt() ?? 0,
      clubName: j['club_name'] as String? ?? '',
      courseName: j['course_name'] as String? ?? '',
      city: loc['city'] as String? ?? '',
      state: loc['state'] as String? ?? '',
      country: loc['country'] as String? ?? '',
      latitude: (loc['latitude'] as num?)?.toDouble(),
      longitude: (loc['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'club_name': clubName,
        'course_name': courseName,
        'location': {
          'city': city,
          'state': state,
          'country': country,
          'latitude': latitude,
          'longitude': longitude,
        },
      };
}

class GolfApiCourseDetail {
  final GolfApiCourse info;
  final List<GolfApiTee> maleTees;
  final List<GolfApiTee> femaleTees;

  const GolfApiCourseDetail({
    required this.info,
    required this.maleTees,
    required this.femaleTees,
  });

  /// Returns male tees if available, otherwise female tees.
  List<GolfApiTee> get availableTees =>
      maleTees.isNotEmpty ? maleTees : femaleTees;

  bool get hasTeeData => maleTees.isNotEmpty || femaleTees.isNotEmpty;

  factory GolfApiCourseDetail.fromJson(Map<String, dynamic> j) {
    final tees = j['tees'];
    List<GolfApiTee> parseTeeList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((t) => GolfApiTee.fromJson(t as Map<String, dynamic>)).toList();
      }
      return [];
    }

    List<GolfApiTee> male = [];
    List<GolfApiTee> female = [];

    if (tees is Map<String, dynamic>) {
      male = parseTeeList(tees['male']);
      female = parseTeeList(tees['female']);
    }

    return GolfApiCourseDetail(
      info: GolfApiCourse.fromJson(j),
      maleTees: male,
      femaleTees: female,
    );
  }

  Map<String, dynamic> toJson() => {
        ...info.toJson(),
        'tees': {
          'male': maleTees.map((t) => t.toJson()).toList(),
          'female': femaleTees.map((t) => t.toJson()).toList(),
        },
      };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class GolfCourseApiService {
  static const _baseUrl = 'https://api.golfcourseapi.com/v1';
  static const _apiKey  = 'DMCV5I5QJIXVZZCR3YRFATZRTE';
  static const _timeout = Duration(seconds: 10);

  static Map<String, String> get _headers => {
        'Authorization': 'Key $_apiKey',
        'Content-Type': 'application/json',
      };

  // ── Search ────────────────────────────────────────────────────────────────

  /// Search courses by name / city. Returns up to ~20 results.
  static Future<List<GolfApiCourse>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
          '$_baseUrl/search?search_query=${Uri.encodeQueryComponent(query.trim())}');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = data['courses'] as List<dynamic>? ?? [];
      return list
          .map((e) => GolfApiCourse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Course detail with cache-aside ────────────────────────────────────────

  /// Finds the best GolfCourseAPI match for a Google Places course.
  ///
  /// Strategy:
  /// 1. Search by full course name (normalized). Works for many courses.
  /// 2. If empty, search by city extracted from [address] (e.g. "Pleasanton").
  ///    The GolfCourseAPI returns results for city searches but not always for
  ///    full proper names like "The Pleasanton Golf Club".
  /// 3. Score results by word overlap between the API club name and the Places name.
  /// 4. Return null if no result reaches a confidence threshold (≥ 1 word overlap).
  static Future<GolfApiCourseDetail?> findBestMatch(
    String googlePlacesName, {
    String? address,
  }) async {
    final cleanedName = _normalize(googlePlacesName);
    if (cleanedName.isEmpty) return null;

    // Build candidate query list: full name first, then city fallback
    final queries = <String>[cleanedName];
    if (address != null) {
      final city = _extractCity(address);
      if (city.isNotEmpty && city != cleanedName) queries.add(city);
    }

    final queryWords = cleanedName.split(' ').where((w) => w.length > 2).toSet();
    GolfApiCourse? best;
    int bestScore = 0;

    for (final q in queries) {
      final results = await search(q);
      for (final r in results) {
        final nameWords = _normalize(r.clubName).split(' ').toSet();
        final overlap   = queryWords.intersection(nameWords).length;
        if (overlap > bestScore) { bestScore = overlap; best = r; }
      }
      // Stop early once we have a confident match
      if (bestScore >= 2) break;
    }

    if (best == null || bestScore < 1) return null;
    return getCourse(best.id);
  }

  /// Extracts a short city token from a Google Places address string.
  /// e.g. "4501 Pleasanton Ave, Pleasanton, CA 94566, USA" → "pleasanton"
  static String _extractCity(String address) {
    final parts = address.split(',');
    if (parts.length >= 2) {
      return _normalize(parts[parts.length - 3 < 0 ? 0 : parts.length - 3]);
    }
    return '';
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'\bthe\b|\ba\b'), '')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Fetch full course detail (with tees + holes).
  /// Checks local cache first; fetches from API on miss and saves to cache.
  static Future<GolfApiCourseDetail?> getCourse(int id) async {
    // 1. Try cache
    final cached = await _loadFromCache(id);
    if (cached != null) return cached;

    // 2. Fetch from API
    final detail = await _fetchFromApi(id);
    if (detail != null) await _saveToCache(id, detail.toJson());
    return detail;
  }

  static Future<GolfApiCourseDetail?> _fetchFromApi(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/courses/$id');
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final courseJson = data['course'] as Map<String, dynamic>?;
      if (courseJson == null) return null;
      return GolfApiCourseDetail.fromJson(courseJson);
    } catch (_) {
      return null;
    }
  }

  // ── SharedPreferences cache ───────────────────────────────────────────────

  static String _cacheKey(int id) => 'gcapi_course_$id';

  static Future<GolfApiCourseDetail?> _loadFromCache(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(id));
      if (raw == null) return null;
      final j = json.decode(raw) as Map<String, dynamic>;
      return GolfApiCourseDetail.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveToCache(int id, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(id), json.encode(data));
    } catch (_) {}
  }

  /// Clears cached data for a specific course (e.g. to force refresh).
  static Future<void> clearCache(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(id));
  }
}
