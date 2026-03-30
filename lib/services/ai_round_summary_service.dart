import 'dart:convert';
import 'package:http/http.dart' as http;
import 'remote_config_service.dart';
import '../models/round_summary_ai.dart';

class AIRoundSummaryService {
  static String get _apiKey => RemoteConfigService.geminiApiKey;
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static final Map<String, RoundSummaryAI> _cache = {};

  static Future<RoundSummaryAI> generateSummary({
    required String roundId,
    required String courseName,
    required int totalHoles,
    required int score,
    required int par,
    required int front9,
    required int back9,
    required int putts,
    required int fairwaysHit,
    required int fairwaysTotal,
    required int gir,
    required int birdies,
    required int pars,
    required int bogeys,
    required int doublePlus,
    required int bestHole,
    required int worstHole,
    required int calories,
  }) async {
    if (_cache.containsKey(roundId)) return _cache[roundId]!;

    final diff = score - par;
    final diffLabel = diff == 0 ? 'even' : diff > 0 ? '+$diff' : '$diff';

    try {
      final result = await _callWithRetry(
        courseName:    courseName,
        totalHoles:    totalHoles,
        score:         score,
        par:           par,
        diffLabel:     diffLabel,
        front9:        front9,
        back9:         back9,
        putts:         putts,
        fairwaysHit:   fairwaysHit,
        fairwaysTotal: fairwaysTotal,
        gir:           gir,
        birdies:       birdies,
        pars:          pars,
        bogeys:        bogeys,
        doublePlus:    doublePlus,
        bestHole:      bestHole,
        worstHole:     worstHole,
        calories:      calories,
      );
      _cache[roundId] = result;
      return result;
    } catch (_) {
      final fallback = _fallback(
        score:         score,
        par:           par,
        diffLabel:     diffLabel,
        putts:         putts,
        fairwaysHit:   fairwaysHit,
        fairwaysTotal: fairwaysTotal,
        gir:           gir,
        birdies:       birdies,
        totalHoles:    totalHoles,
        calories:      calories,
      );
      _cache[roundId] = fallback;
      return fallback;
    }
  }

  static Future<RoundSummaryAI> _callWithRetry({
    required String courseName,
    required int totalHoles,
    required int score,
    required int par,
    required String diffLabel,
    required int front9,
    required int back9,
    required int putts,
    required int fairwaysHit,
    required int fairwaysTotal,
    required int gir,
    required int birdies,
    required int pars,
    required int bogeys,
    required int doublePlus,
    required int bestHole,
    required int worstHole,
    required int calories,
  }) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        return await _call(
          courseName:    courseName,
          totalHoles:    totalHoles,
          score:         score,
          par:           par,
          diffLabel:     diffLabel,
          front9:        front9,
          back9:         back9,
          putts:         putts,
          fairwaysHit:   fairwaysHit,
          fairwaysTotal: fairwaysTotal,
          gir:           gir,
          birdies:       birdies,
          pars:          pars,
          bogeys:        bogeys,
          doublePlus:    doublePlus,
          bestHole:      bestHole,
          worstHole:     worstHole,
          calories:      calories,
        );
      } catch (e) {
        if (attempt == 1) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('unreachable');
  }

  static Future<RoundSummaryAI> _call({
    required String courseName,
    required int totalHoles,
    required int score,
    required int par,
    required String diffLabel,
    required int front9,
    required int back9,
    required int putts,
    required int fairwaysHit,
    required int fairwaysTotal,
    required int gir,
    required int birdies,
    required int pars,
    required int bogeys,
    required int doublePlus,
    required int bestHole,
    required int worstHole,
    required int calories,
  }) async {
    final prompt = _buildPrompt(
      courseName:    courseName,
      totalHoles:    totalHoles,
      score:         score,
      diffLabel:     diffLabel,
      par:           par,
      front9:        front9,
      back9:         back9,
      putts:         putts,
      fairwaysHit:   fairwaysHit,
      fairwaysTotal: fairwaysTotal,
      gir:           gir,
      birdies:       birdies,
      pars:          pars,
      bogeys:        bogeys,
      doublePlus:    doublePlus,
      bestHole:      bestHole,
      worstHole:     worstHole,
      calories:      calories,
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
              'maxOutputTokens': 300,
            },
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['candidates'] as List).first['content']['parts'].first['text'] as String;

    // Strip markdown code fences if present
    final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final parsed = jsonDecode(clean) as Map<String, dynamic>;

    // Ensure calories falls back to the locally-calculated value if AI omits it
    if (!parsed.containsKey('calories') || parsed['calories'] == null) {
      parsed['calories'] = calories;
    }
    return RoundSummaryAI.fromJson(parsed);
  }

  static String _buildPrompt({
    required String courseName,
    required int totalHoles,
    required int score,
    required String diffLabel,
    required int par,
    required int front9,
    required int back9,
    required int putts,
    required int fairwaysHit,
    required int fairwaysTotal,
    required int gir,
    required int birdies,
    required int pars,
    required int bogeys,
    required int doublePlus,
    required int bestHole,
    required int worstHole,
    required int calories,
  }) =>
      '''You are an elite golf performance coach. Analyze this round and respond in JSON only.

Round: $courseName, $totalHoles holes
Score: $score ($diffLabel par $par)
Front 9: $front9 | Back 9: $back9
Putts: $putts | GIR: $gir/$totalHoles | Fairways: $fairwaysHit/$fairwaysTotal
Birdies: $birdies | Pars: $pars | Bogeys: $bogeys | Double+: $doublePlus
Best hole: #$bestHole | Worst: #$worstHole
Estimated calories burned: $calories kcal

Return ONLY valid JSON (no markdown, no extra text):
{"headline":"...","summary":"...","strength":"...","weakness":"...","focusArea":"...","calories":$calories}

Rules:
- headline: 6-8 words, punchy
- summary: 2 sentences max, specific to this round. Mention calories naturally in one sentence — do not make it the focus. Example style: "You finished at $score and burned around $calories calories on the course."
- strength: 1 sentence, what went well
- weakness: 1 sentence, what hurt the score
- focusArea: 1 actionable drill or focus for next round
- calories: return the integer $calories exactly as provided
- Total under 90 words. Coach tone. No generic phrases. No medical claims.''';

  static RoundSummaryAI _fallback({
    required int score,
    required int par,
    required String diffLabel,
    required int putts,
    required int fairwaysHit,
    required int fairwaysTotal,
    required int gir,
    required int birdies,
    required int totalHoles,
    required int calories,
  }) {
    final girPct   = totalHoles > 0 ? (gir / totalHoles * 100).round() : 0;
    final fhPct    = fairwaysTotal > 0 ? (fairwaysHit / fairwaysTotal * 100).round() : 0;
    final avgPutts = totalHoles > 0 ? (putts / totalHoles).toStringAsFixed(1) : '-';

    final strong = gir >= totalHoles * 0.5
        ? 'ball-striking'
        : fairwaysHit >= fairwaysTotal * 0.6
            ? 'driving accuracy'
            : birdies > 1
                ? 'scoring opportunities'
                : 'course management';

    final weak = putts > totalHoles * 2
        ? 'putting'
        : girPct < 35
            ? 'approach shots'
            : fhPct < 50
                ? 'driving'
                : 'short game';

    return RoundSummaryAI(
      headline: score <= par ? 'Solid round at par or better' : 'A round with room to grow',
      summary:
          'You finished $diffLabel with $putts total putts and hit $gir/$totalHoles greens in regulation, '
          'burning around $calories calories on the course.',
      strength: 'Your $strong showed promise — $girPct% GIR is a solid foundation.',
      weakness: 'Your $weak ($avgPutts avg putts/hole) is the main area costing strokes.',
      focusArea: weak == 'putting'
          ? 'Spend 15 min on lag putts from 20+ feet — distance control is everything.'
          : weak == 'approach shots'
              ? 'Focus on landing zone selection: aim for the fat part of the green.'
              : 'Work on your pre-shot routine off the tee to improve consistency.',
      calories: calories,
    );
  }
}
