import 'dart:convert';
import 'package:http/http.dart' as http;
import 'remote_config_service.dart';
import '../models/pressure_profile.dart';
import '../models/pressure_narrative.dart';

class AIPressureNarrativeService {
  static String get _apiKey => RemoteConfigService.geminiApiKey;
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static final Map<String, PressureNarrative> _cache = {};

  static Future<PressureNarrative> generate(PressureProfile profile) async {
    final key = '${profile.compositeScore}_${profile.roundsAnalyzed}';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final result = await _callWithRetry(profile);
      _cache[key] = result;
      return result;
    } catch (_) {
      const fallback = PressureNarrative.fallback();
      _cache[key] = fallback;
      return fallback;
    }
  }

  static Future<PressureNarrative> _callWithRetry(PressureProfile profile) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        return await _call(profile);
      } catch (e) {
        if (attempt == 1) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('unreachable');
  }

  static Future<PressureNarrative> _call(PressureProfile profile) async {
    final prompt = _buildPrompt(profile);

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
              'maxOutputTokens': 600,
            },
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final body   = jsonDecode(response.body) as Map<String, dynamic>;
    final text   = (body['candidates'] as List).first['content']['parts'].first['text'] as String;
    final clean  = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final parsed = jsonDecode(clean) as Map<String, dynamic>;

    return PressureNarrative.fromJson(parsed);
  }

  static String _buildPrompt(PressureProfile p) {
    String fmt(PressureMetric m) {
      final deltaStr = m.sampleSize < 3
          ? 'insufficient data'
          : '${m.delta >= 0 ? '+' : ''}${m.delta.toStringAsFixed(2)} (${m.sampleSize} samples) — ${m.isSignificant ? 'SIGNIFICANT' : 'normal'}';
      return deltaStr;
    }

    final opening   = p.metricById(kMetricOpeningHole);
    final birdie    = p.metricById(kMetricBirdieHangover);
    final backNine  = p.metricById(kMetricBackNine);
    final finishing = p.metricById(kMetricFinishingStretch);
    final threePutt = p.metricById(kMetricThreePutt);

    return '''
You are an elite sports psychologist and golf coach.
Analyzed ${p.roundsAnalyzed} rounds. Baseline: ${p.baselineAvgDiff.toStringAsFixed(2)} avg strokes vs par per hole.

Pressure patterns found:
1. Opening Hole Syndrome: ${opening != null ? fmt(opening) : 'no data'}
2. Birdie Hangover: ${birdie != null ? fmt(birdie) : 'no data'}
3. Back-Nine Decay: ${backNine != null ? fmt(backNine) : 'no data'}
4. Finishing Stretch Collapse: ${finishing != null ? fmt(finishing) : 'no data'}
5. Three-Putt Timing (ratio vs normal holes): ${threePutt != null ? fmt(threePutt) : 'no data'}

Return ONLY valid JSON (no markdown fences):
{"headline":"one sentence max 12 words summarising the biggest pressure leak","overallInsight":"2-3 sentences on overall mental game","metricInsights":[{"metricId":"opening_hole","insight":"1-2 sentences","drill":"one specific drill"},{"metricId":"birdie_hangover","insight":"...","drill":"..."},{"metricId":"back_nine","insight":"...","drill":"..."},{"metricId":"finishing_stretch","insight":"...","drill":"..."},{"metricId":"three_putt","insight":"...","drill":"..."}],"topDrill":"single best drill addressing the worst SIGNIFICANT pattern"}
''';
  }
}
