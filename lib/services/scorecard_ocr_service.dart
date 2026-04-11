import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'remote_config_service.dart';
import '../models/scorecard_import_data.dart';

class ScorecardNotDetectedException implements Exception {
  final String reason;
  const ScorecardNotDetectedException(this.reason);
  @override
  String toString() => 'ScorecardNotDetectedException: $reason';
}

class HoleCountException implements Exception {
  final int foundCount;
  const HoleCountException(this.foundCount);
  @override
  String toString() => 'HoleCountException: found $foundCount holes';
}

class ScorecardOcrService {
  static String get _apiKey => RemoteConfigService.geminiApiKey;
  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';

  static const String _prompt = '''
You are an AI system specialized in extracting structured data from golf scorecard images.

## Step 1: Validate the Image
Determine if the image is a golf scorecard. A valid golf scorecard typically contains:
- A row labeled "HOLE" with numbers (usually 1–9 or 1–18)
- A row labeled "PAR"
- A grid/table structure
- Numeric values representing distances or scores

If the image is NOT a golf scorecard, return ONLY:
{"is_scorecard": false, "reason": "<brief explanation>"}

## Step 2: Extract Data (if valid)
Extract:
- course_name (string)
- holes array, each with: hole_number (integer), par (integer or null), score (integer or null)
- front9_total (integer or null)
- back9_total (integer or null)
- total_score (integer or null)

## Step 3: Data Mapping Rules
- Map columns under "HOLE" to hole_number
- The PAR row may contain values like "Par 4", "Par 3", "Par 5" or just "4", "3", "5" — extract only the numeric value (3, 4, or 5)
- Identify ALL player score rows that contain filled-in numeric scores (ignore blank/empty rows and ignore the Par row)
- If multiple players exist, extract ALL player rows (up to 4). Each player has their own score row in the scorecard grid. Return them in the "players" array.
- If only one player's scores are visible, return a single-item "players" array.
- If a player name is printed or written next to their row, capture it as player_name; otherwise use "".
- If all score cells are blank or empty for a player, set score to null for all their holes
- Ignore distance/yardage rows

## Step 4: Validation Rules
- hole_number must be sequential (1–9 or 1–18)
- par must be between 3 and 5 (if present)
- score must be between 1 and 12 (if present)
- totals must equal sum of scores if clearly visible
- If inconsistencies exist, still return data and add a "warnings" field

## Step 5: Output Format (STRICT)
Return ONLY valid JSON. No explanation, no markdown.

{
  "is_scorecard": true,
  "course_name": "Skyline Wilderness Park",
  "players": [
    {
      "player_name": "",
      "holes": [
        {"hole_number": 1, "par": 4, "score": 5},
        {"hole_number": 2, "par": 3, "score": 3}
      ]
    }
  ],
  "front9_total": 36,
  "back9_total": 40,
  "total_score": 76,
  "warnings": []
}

- If any value is missing or unclear, use null
- Do not guess values unless reasonably confident
- Preserve numeric accuracy over completeness
- Ignore logos, decorations, and non-tabular text
- Be robust to rotated, skewed, or partially visible images
''';

  /// Analyzes a scorecard image and returns structured import data.
  ///
  /// Throws [ScorecardNotDetectedException] if the image is not a scorecard.
  /// Throws [HoleCountException] if the extracted hole count is unexpected
  /// but still returns partial data via the exception's roundData field.
  /// Throws [Exception] for network or parse errors.
  static Future<ScorecardImportData> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Detect MIME type from file extension — iOS may produce PNG or HEIC
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'png'  => 'image/png',
      'webp' => 'image/webp',
      _      => 'image/jpeg', // jpg, jpeg, heic converted by ImagePicker
    };

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 8192,
        'responseMimeType': 'application/json', // force pure JSON, no markdown
      },
    });

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
    }

    // Parse response safely without chained firstOrNull on dynamic
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates. Response: ${response.body}');
    }
    final parts = (candidates[0] as Map)['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini returned no parts. Response: ${response.body}');
    }
    final text = (parts[0] as Map)['text'] as String? ?? '';

    return _parseResponse(text.trim());
  }

  static ScorecardImportData _parseResponse(String raw) {
    // Strip markdown fences
    var clean = raw;
    if (clean.contains('```')) {
      clean = clean.replaceAll(RegExp(r'```[a-z]*\n?'), '').replaceAll('```', '');
    }

    // Extract the outermost JSON object in case Gemini adds surrounding text
    final start = clean.indexOf('{');
    final end   = clean.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw Exception('No JSON object found in Gemini response: $raw');
    }
    clean = clean.substring(start, end + 1);

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Could not parse Gemini response as JSON.');
    }

    // Not a scorecard
    if (json['is_scorecard'] == false) {
      final reason = json['reason'] as String? ?? 'Not a golf scorecard.';
      throw ScorecardNotDetectedException(reason);
    }

    final courseName = json['course_name'] as String? ?? '';

    // Parse players array (new format). Fall back to legacy top-level "holes" key.
    final rawPlayers = json['players'] as List?;
    final rawLegacyHoles = json['holes'] as List?;

    List<PlayerImportData> parsePlayers(List rawList) {
      final result = <PlayerImportData>[];
      for (final p in rawList) {
        final name = p['player_name'] as String? ?? '';
        final rawHoles = (p['holes'] as List?) ?? [];
        final holes = _parseHoles(rawHoles);
        holes.sort((a, b) => a.hole.compareTo(b.hole));
        result.add(PlayerImportData(playerName: name, holes: holes));
      }
      return result;
    }

    final List<PlayerImportData> players;

    if (rawPlayers != null && rawPlayers.isNotEmpty) {
      players = parsePlayers(rawPlayers);
    } else if (rawLegacyHoles != null) {
      // Legacy response shape — wrap in a single player
      final holes = _parseHoles(rawLegacyHoles);
      holes.sort((a, b) => a.hole.compareTo(b.hole));
      players = [PlayerImportData(playerName: '', holes: holes)];
    } else {
      players = [PlayerImportData(playerName: '', holes: [])];
    }

    // Build warning message based on first player's hole count
    final geminiWarnings = (json['warnings'] as List?)
            ?.map((w) => w.toString())
            .where((w) => w.isNotEmpty)
            .toList() ??
        [];

    final totalHoles = players.first.holes.length;
    final hasUnreadable = players.any((p) => p.hasUnreadableScores);

    final allWarnings = [
      ...geminiWarnings,
      if (hasUnreadable)
        'Some scores could not be read — tap the red cells to fix them.',
    ];

    String? warningMessage;
    if (totalHoles != 9 && totalHoles != 18) {
      warningMessage =
          'We found $totalHoles holes — please check and remove any extra rows.';
      if (allWarnings.isNotEmpty) {
        warningMessage = '$warningMessage\n${allWarnings.join('\n')}';
      }
    } else if (allWarnings.isNotEmpty) {
      warningMessage = allWarnings.join('\n');
    }

    return ScorecardImportData(
      courseName: courseName,
      courseLocation: '',
      totalHoles: (totalHoles == 9) ? 9 : 18,
      players: players,
      roundDate: DateTime.now(),
      warningMessage: warningMessage,
    );
  }

  static List<ImportedHole> _parseHoles(List rawHoles) {
    final holes = <ImportedHole>[];
    for (final h in rawHoles) {
      final holeNum = h['hole_number'] as int? ?? 0;
      if (holeNum <= 0) continue;

      var par = h['par'] as int? ?? 4;
      if (par < 3 || par > 5) par = 4;

      final rawScore = h['score'] as int?;
      final score = (rawScore != null && rawScore >= 1 && rawScore <= 12)
          ? rawScore
          : 0;

      holes.add(ImportedHole(hole: holeNum, par: par, score: score));
    }
    return holes;
  }
}
