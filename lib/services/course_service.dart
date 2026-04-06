import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/course_model.dart';
import 'golf_course_api_service.dart';
import 'remote_config_service.dart';

class CourseService {
  static final _db = FirebaseFirestore.instance;

  static const _extractionPrompt = '''
Extract golf scorecard data from this image.
Return ONLY valid JSON with no markdown, no code fences, no extra text.
Schema:
{
  "courseName": "string or empty string if not visible",
  "location": "City, State or empty string if not visible",
  "tees": [
    {
      "name": "tee name (e.g. Black, White, Blue, Red)",
      "courseRating": number,
      "slopeRating": integer,
      "holes": [
        { "hole": integer, "par": integer, "yardage": integer, "handicap": integer }
      ]
    }
  ]
}
Rules:
- Include all tee sets visible on the scorecard.
- holes array must have exactly 9 or 18 entries.
- If a value is unreadable, use 0.
- courseRating and slopeRating default to 0 if not shown.''';

  // Normalize a course name to a Firestore doc ID
  static String docId(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');

  /// Look up a course in Firestore by name.
  /// Tries exact normalized doc ID first, then falls back to a name-field
  /// query so minor name differences (abbreviations, punctuation) still match.
  static Future<CourseData?> findCourse(String name) async {
    // 1. Exact doc ID match
    final id  = docId(name);
    final doc = await _db.collection('courses').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return CourseData.fromJson(id, doc.data()!);
    }

    // 2. Name-field query fallback
    final nameNorm = name.toLowerCase();
    final snap = await _db.collection('courses').get();
    for (final d in snap.docs) {
      final saved = (d.data()['name'] as String? ?? '').toLowerCase();
      if (saved == nameNorm ||
          saved.contains(nameNorm) ||
          nameNorm.contains(saved)) {
        return CourseData.fromJson(d.id, d.data());
      }
    }
    return null;
  }

  /// Save or overwrite a course document in Firestore.
  static Future<void> saveCourse(CourseData course, String uid) async {
    final id = docId(course.name);
    await _db.collection('courses').doc(id).set({
      ...course.toJson(),
      'submittedBy': uid,
      'updatedAt':   FieldValue.serverTimestamp(),
    });
  }

  /// Call Gemini Flash vision directly to extract scorecard data.
  static Future<Map<String, dynamic>> analyzeScorecard(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    final model = GenerativeModel(
      model:  'gemini-2.5-flash',
      apiKey: RemoteConfigService.geminiApiKey,
    );
    final response = await model.generateContent([
      Content.multi([
        TextPart(_extractionPrompt),
        DataPart(mimeType, imageBytes),
      ]),
    ]);

    final raw = response.text?.trim() ?? '';
    final jsonText = raw
        .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: false), '')
        .replaceAll(RegExp(r'\s*```$',           multiLine: false), '');
    return Map<String, dynamic>.from(jsonDecode(jsonText) as Map);
  }

  /// Convert a [CourseTee] into a [List<GolfApiHole>] for ScorecardScreen compat.
  static List<GolfApiHole> toGolfApiHoles(CourseTee tee) {
    return tee.effectiveHoles
        .map((h) => GolfApiHole(
              hole:     h.hole,
              par:      h.par,
              yardage:  h.yardage,
              handicap: h.handicap,
            ))
        .toList();
  }
}
