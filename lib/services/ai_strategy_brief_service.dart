import 'dart:convert';
import 'package:http/http.dart' as http;
import 'remote_config_service.dart';
import '../models/round_strategy_brief.dart';
import '../models/round.dart';
import '../models/course_model.dart';
import 'stats_service.dart';
import 'strokes_gained_service.dart';
import '../services/golf_course_api_service.dart';

// Internal hole representation shared by GolfAPI and Firestore tees
class _TeeHole {
  final int hole;
  final int par;
  final int yardage;
  final int handicap;
  const _TeeHole({required this.hole, required this.par, required this.yardage, required this.handicap});
}

class AIStrategyBriefService {
  static String get _apiKey => RemoteConfigService.geminiApiKey;
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // Cache by course+tee key so repeated tee switches don't re-call
  static final Map<String, RoundStrategyBrief> _cache = {};

  /// Generate brief from GolfAPI tee (external course data).
  static Future<RoundStrategyBrief?> generateBrief({
    required String courseName,
    required GolfApiTee tee,
    required List<Round> rounds,
  }) =>
      _generate(
        courseName: courseName,
        courseRating: tee.courseRating,
        slopeRating: tee.slopeRating,
        parTotal: tee.parTotal,
        totalYards: tee.totalYards,
        teeName: tee.name,
        holes: tee.effectiveHoles
            .map((h) => _TeeHole(hole: h.hole, par: h.par, yardage: h.yardage, handicap: h.handicap))
            .toList(),
        rounds: rounds,
      );

  /// Generate brief from Firestore-uploaded CourseTee (scorecard upload).
  static Future<RoundStrategyBrief?> generateBriefFromFirestore({
    required String courseName,
    required CourseTee tee,
    required List<Round> rounds,
  }) {
    final effective = tee.effectiveHoles;
    final parTotal = effective.fold(0, (s, h) => s + h.par);
    final totalYards = effective.fold(0, (s, h) => s + h.yardage);
    return _generate(
      courseName: courseName,
      courseRating: tee.courseRating,
      slopeRating: tee.slopeRating,
      parTotal: parTotal,
      totalYards: totalYards,
      teeName: tee.name,
      holes: effective
          .map((h) => _TeeHole(hole: h.hole, par: h.par, yardage: h.yardage, handicap: h.handicap))
          .toList(),
      rounds: rounds,
    );
  }

  static Future<RoundStrategyBrief?> _generate({
    required String courseName,
    required double courseRating,
    required int slopeRating,
    required int parTotal,
    required int totalYards,
    required String teeName,
    required List<_TeeHole> holes,
    required List<Round> rounds,
  }) async {
    final cacheKey = '${courseName}_${teeName}_$courseRating';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    if (rounds.isEmpty) return null;

    final stats = StatsService.calculate(rounds);
    final sg = StrokesGainedService.calculate(rounds);

    try {
      final brief = await _callWithRetry(
        courseName: courseName,
        courseRating: courseRating,
        slopeRating: slopeRating,
        parTotal: parTotal,
        totalYards: totalYards,
        holes: holes,
        stats: stats,
        sg: sg,
      );
      _cache[cacheKey] = brief;
      return brief;
    } catch (_) {
      final fallback = _fallback(
        courseRating: courseRating,
        slopeRating: slopeRating,
        holes: holes,
        stats: stats,
        sg: sg,
      );
      _cache[cacheKey] = fallback;
      return fallback;
    }
  }

  static Future<RoundStrategyBrief> _callWithRetry({
    required String courseName,
    required double courseRating,
    required int slopeRating,
    required int parTotal,
    required int totalYards,
    required List<_TeeHole> holes,
    required AppStats stats,
    required StrokesGained sg,
  }) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        return await _call(
          courseName: courseName,
          courseRating: courseRating,
          slopeRating: slopeRating,
          parTotal: parTotal,
          totalYards: totalYards,
          holes: holes,
          stats: stats,
          sg: sg,
        );
      } catch (e) {
        if (attempt == 1) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('unreachable');
  }

  static Future<RoundStrategyBrief> _call({
    required String courseName,
    required double courseRating,
    required int slopeRating,
    required int parTotal,
    required int totalYards,
    required List<_TeeHole> holes,
    required AppStats stats,
    required StrokesGained sg,
  }) async {
    final prompt = _buildPrompt(
      courseName: courseName,
      courseRating: courseRating,
      slopeRating: slopeRating,
      parTotal: parTotal,
      totalYards: totalYards,
      holes: holes,
      stats: stats,
      sg: sg,
    );

    final response = await http
        .post(
          Uri.parse('$_endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 400,
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['candidates'] as List).first['content']['parts'].first['text'] as String;
    final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final parsed = jsonDecode(clean) as Map<String, dynamic>;
    return RoundStrategyBrief.fromJson(parsed);
  }

  static String _buildPrompt({
    required String courseName,
    required double courseRating,
    required int slopeRating,
    required int parTotal,
    required int totalYards,
    required List<_TeeHole> holes,
    required AppStats stats,
    required StrokesGained sg,
  }) {
    final par3s = holes.where((h) => h.par == 3).length;
    final par4s = holes.where((h) => h.par == 4).length;
    final par5s = holes.where((h) => h.par == 5).length;

    final sorted = [...holes]..sort((a, b) => a.handicap.compareTo(b.handicap));
    final hardest = sorted.take(3).map((h) => 'Hole ${h.hole} (par ${h.par}, ${h.yardage}y)').join(', ');
    final easiest = sorted.reversed.take(3).map((h) => 'Hole ${h.hole} (par ${h.par}, ${h.yardage}y)').join(', ');

    final handicapLine = stats.handicapIndex != null
        ? 'Handicap Index: ${stats.handicapLabel}'
        : '${stats.totalRounds}/20 rounds played (handicap not yet calculated)';

    final sgMap = {
      'Off the Tee': sg.offTee,
      'Approach': sg.approach,
      'Short Game': sg.aroundGreen,
      'Putting': sg.putting,
    };
    final weakest = sgMap.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    final diffLabel = stats.avgScore == 0
        ? 'even'
        : stats.avgScore > 0
            ? '+${stats.avgScore.toStringAsFixed(1)}'
            : stats.avgScore.toStringAsFixed(1);

    return '''You are an elite golf performance coach preparing a player for their round. Analyze the player profile and course, then produce a personalized pre-round strategy brief.

PLAYER PROFILE:
- $handicapLine
- Avg score: $diffLabel vs par | Best round: ${stats.bestRoundScore > 0 ? stats.bestRoundScore : 'N/A'}
- Fairways Hit: ${stats.fairwaysHitPct.toStringAsFixed(0)}% | GIR: ${stats.girPct.toStringAsFixed(0)}% | Avg putts/hole: ${stats.avgPutts.toStringAsFixed(2)}

STROKES GAINED vs SCRATCH:
- Off tee: ${sg.offTee >= 0 ? '+' : ''}${sg.offTee.toStringAsFixed(1)}
- Approach: ${sg.approach >= 0 ? '+' : ''}${sg.approach.toStringAsFixed(1)}
- Short game: ${sg.aroundGreen >= 0 ? '+' : ''}${sg.aroundGreen.toStringAsFixed(1)}
- Putting: ${sg.putting >= 0 ? '+' : ''}${sg.putting.toStringAsFixed(1)}
- Biggest weakness: $weakest

COURSE:
- $courseName — Rating ${courseRating.toStringAsFixed(1)}, Slope $slopeRating, Par $parTotal, $totalYards yards
- Hole breakdown: $par3s par-3s, $par4s par-4s, $par5s par-5s
- Hardest holes (stroke index 1-3): $hardest
- Easiest holes (stroke index 16-18): $easiest

Return ONLY valid JSON (no markdown, no extra text):
{
  "headline": "4-6 words, today's tactical focus",
  "strategy": "2-3 sentences on course management for this player on this specific course",
  "keyFocus": "1-2 specific areas to prioritize today",
  "holeCoachingTips": [
    {"parType": "Par 3s", "tip": "specific actionable advice for par 3s based on player stats"},
    {"parType": "Par 4s", "tip": "specific actionable advice for par 4s based on player stats"},
    {"parType": "Par 5s", "tip": "specific actionable advice for par 5s based on player stats"}
  ],
  "putterReminder": "1 sentence on green strategy based on putting stats",
  "confidenceBoost": "1 motivational sentence referencing a real player strength"
}

Rules:
- Reference actual stats (mention specific percentages or numbers)
- Total under 160 words across all fields
- Coach tone, specific and actionable — no generic phrases
- If slope > 130: emphasize precision over distance
- If fairways hit < 50%: recommend conservative tee clubs on hazard holes
- If putting is weakest SG: emphasize lag putting and distance control
- If GIR > 60%: acknowledge strong ball-striking and build confidence on that''';
  }

  static RoundStrategyBrief _fallback({
    required double courseRating,
    required int slopeRating,
    required List<_TeeHole> holes,
    required AppStats stats,
    required StrokesGained sg,
  }) {
    final sgMap = {
      'Off the Tee': sg.offTee,
      'Approach': sg.approach,
      'Short Game': sg.aroundGreen,
      'Putting': sg.putting,
    };
    final weakest = sgMap.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    final strongest = sgMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final aggressive = slopeRating <= 125;

    return RoundStrategyBrief(
      headline: aggressive ? 'Trust Your Game Today' : 'Precision Over Power',
      strategy: 'At ${courseRating.toStringAsFixed(1)} rating and $slopeRating slope, '
          '${slopeRating > 130 ? 'this is a demanding track — prioritise course management over aggression. ' : 'this course suits your game. '}'
          'Your ${stats.girPct.toStringAsFixed(0)}% GIR average gives you a solid foundation.',
      keyFocus: '1) Focus on $weakest — your biggest opportunity for strokes saved. '
          '2) Leverage your $strongest strength to build momentum.',
      holeCoachingTips: [
        const HoleTypeCoachingTip(
          parType: 'Par 3s',
          tip: 'Commit to one club. Aim for the middle of the green — avoid short-side misses.',
        ),
        HoleTypeCoachingTip(
          parType: 'Par 4s',
          tip: stats.fairwaysHitPct < 50
              ? 'Consider 3-wood off tight tee shots. Fairways first — ${stats.fairwaysHitPct.toStringAsFixed(0)}% is the area to improve.'
              : 'Your ${stats.fairwaysHitPct.toStringAsFixed(0)}% fairway rate is solid. Pick a specific target and commit.',
        ),
        const HoleTypeCoachingTip(
          parType: 'Par 5s',
          tip: "Play to your favourite approach yardage. Don't force the green in 2 unless the risk is minimal.",
        ),
      ],
      putterReminder: stats.avgPutts > 1.9
          ? 'Lag putting is crucial — focus on distance control from outside 15 feet.'
          : 'Your putting is steady. Trust your read and commit to your line.',
      confidenceBoost: 'Your $strongest is a genuine weapon today — lean on it when the pressure builds.',
    );
  }
}
