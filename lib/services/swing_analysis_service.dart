import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
// import 'package:video_compress/video_compress.dart'; // removed — unmaintained
import '../models/swing_analysis.dart';

class SwingAnalysisService {
  static const String _apiKey = 'AIzaSyB6S8HpcnyuaOD-giUnDHHdxb2Eg9-TKpU';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static final _db = FirebaseFirestore.instance;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Analyze a local video file. Returns SwingAnalysis with ball path + shot data.
  /// Transcodes to H.264 first to handle Dolby Vision / HEVC / ProRes formats.
  /// Always uses inline base64 — works with AI Studio free keys (no Files API needed).
  static Future<SwingAnalysis> analyzeVideo(
    File videoFile, {
    void Function(double progress)? onProgress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // ── Ball tracking disabled — re-enable block below when ready ─────────────
    return SwingAnalysis(
      userId: uid,
      createdAt: DateTime.now(),
      videoLocalPath: videoFile.path,
      ballPath: const [],
      shotData: const ShotData(carryYards: 0, maxHeightYards: 0, launchAngle: 0),
    );
    // ── End disabled block ────────────────────────────────────────────────────

    // ignore: dead_code
    // Transcode to H.264 MP4 — handles Dolby Vision, HEVC, ProRes for Gemini upload.
    // We keep the original path for local video playback (plays fine on iOS;
    // Android shows a placeholder if the format is unsupported there).
    // final File processedFile = await _transcodeToH264(
    //   videoFile,
    //   onProgress: onProgress,
    // );

    // final bytes = await processedFile.readAsBytes();
    // final mb = bytes.lengthInBytes / (1024 * 1024);
    // if (mb > 20) {
    //   throw Exception(
    //       'Video is ${mb.toStringAsFixed(1)} MB after compression. Please use a clip under ~30 seconds.');
    // }

    // final geminiJson = await _analyzeInline(bytes);

    // final rawPath = geminiJson['ball_path'] as List? ?? [];
    // final ballPath = rawPath
    //     .map((p) => BallPoint.fromJson(p as Map<String, dynamic>))
    //     .toList()
    //   ..sort((a, b) => a.t.compareTo(b.t));

    // final shotData = ShotData.fromJson(
    //     geminiJson['shot_data'] as Map<String, dynamic>? ?? {});

    // return SwingAnalysis(
    //   userId: uid,
    //   createdAt: DateTime.now(),
    //   videoLocalPath: videoFile.path,
    //   ballPath: ballPath,
    //   shotData: shotData,
    // );
  }

  /// Persist analysis to Firestore (without video bytes).
  static Future<SwingAnalysis> saveAnalysis(SwingAnalysis analysis) async {
    final ref = await _db
        .collection('users')
        .doc(analysis.userId)
        .collection('swingAnalyses')
        .add(analysis.toFirestore());
    return SwingAnalysis(
      id: ref.id,
      userId: analysis.userId,
      createdAt: analysis.createdAt,
      videoLocalPath: analysis.videoLocalPath,
      ballPath: analysis.ballPath,
      shotData: analysis.shotData,
    );
  }

  /// Stream of saved analyses for the current user.
  static Stream<List<SwingAnalysis>> getAnalysesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('swingAnalyses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SwingAnalysis.fromFirestore).toList());
  }

  // ── H.264 transcoding ─────────────────────────────────────────────────────
  // ignore: unused_element

  /// Returns the input file directly (video_compress was removed — unmaintained).
  // ignore: unused_element
  static Future<File> _transcodeToH264(
    File input, {
    void Function(double)? onProgress,
  }) async {
    return input;
  }

  // ── Gemini inline base64 ───────────────────────────────────────────────────
  // ignore: unused_element
  static Future<Map<String, dynamic>> _analyzeInline(List<int> bytes) async {
    final b64 = base64Encode(bytes);
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inlineData': {
                'mimeType': 'video/mp4',
                'data': b64,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 65536,
        'thinkingConfig': {
          'thinkingBudget': 0, // disable thinking mode — much faster response
        },
      },
    });

    final response = await http
        .post(
          Uri.parse('$_endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 180));

    return _parseGeminiResponse(response);
  }

  // ── Response parsing ───────────────────────────────────────────────────────

  static Map<String, dynamic> _parseGeminiResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}\n${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['candidates'] as List).first['content']['parts']
        .first['text'] as String;
    final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();

    // First try parsing as-is
    try {
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      // JSON was truncated — salvage complete ball_path points and build a
      // valid response from whatever Gemini managed to emit.
      return _repairTruncatedJson(clean);
    }
  }

  /// Recover partial Gemini JSON by extracting fully-formed ball_path entries.
  static Map<String, dynamic> _repairTruncatedJson(String raw) {
    // Extract all complete {"t":..., "x":..., "y":...} objects
    final pointRegex = RegExp(
      r'\{\s*"t"\s*:\s*(\d+)\s*,\s*"x"\s*:\s*([\d.]+)\s*,\s*"y"\s*:\s*([\d.]+)\s*\}',
    );
    final points = pointRegex.allMatches(raw).map((m) => {
          't': int.parse(m.group(1)!),
          'x': double.parse(m.group(2)!),
          'y': double.parse(m.group(3)!),
        }).toList();

    // Try to pull out shot_data fields that may have been emitted before truncation
    double carry = 0, height = 0, angle = 0;
    final carryMatch = RegExp(r'"carry_yards"\s*:\s*([\d.]+)').firstMatch(raw);
    final heightMatch = RegExp(r'"max_height_yards"\s*:\s*([\d.]+)').firstMatch(raw);
    final angleMatch = RegExp(r'"launch_angle"\s*:\s*([\d.]+)').firstMatch(raw);
    if (carryMatch != null) carry = double.parse(carryMatch.group(1)!);
    if (heightMatch != null) height = double.parse(heightMatch.group(1)!);
    if (angleMatch != null) angle = double.parse(angleMatch.group(1)!);

    return {
      'ball_path': points,
      'shot_data': {
        'carry_yards': carry,
        'max_height_yards': height,
        'launch_angle': angle,
      },
    };
  }

  // ── Prompt ─────────────────────────────────────────────────────────────────

  static const String _prompt = '''
You are a computer vision expert analyzing a golf swing video.
Your task: track the golf ball through its entire flight path from impact to landing.

Return ONLY valid JSON with no markdown fences, no explanation:
{
  "ball_path": [
    {"t": <milliseconds_from_start>, "x": <0_to_1000>, "y": <0_to_1000>},
    ...
  ],
  "shot_data": {
    "carry_yards": <estimated_number>,
    "max_height_yards": <estimated_number>,
    "launch_angle": <estimated_degrees>
  }
}

Rules:
- t: time in milliseconds from the start of the video when the ball is at this position
- x/y: 0 = left/top edge, 1000 = right/bottom edge of the video frame
- Include a point every ~10 frames (not every frame) — 15-30 points total is enough
- If the ball is not visible in a frame, skip it (do NOT guess)
- Estimate shot_data based on ball trajectory and typical golf physics
- If you cannot detect the ball at all, return {"ball_path": [], "shot_data": {"carry_yards": 0, "max_height_yards": 0, "launch_angle": 0}}
''';
}
