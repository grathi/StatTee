import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/round.dart';
import '../models/hole_score.dart';

class RoundService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('rounds');

  // ── Create ────────────────────────────────────────────────────────────────

  static Future<String> startRound({
    required String courseName,
    required String courseLocation,
    required int totalHoles,
    double? courseRating,
    int? slopeRating,
  }) async {
    final doc = await _col.add(Round(
      userId: _uid,
      courseName: courseName,
      courseLocation: courseLocation,
      totalHoles: totalHoles,
      status: RoundStatus.active,
      startedAt: DateTime.now(),
      courseRating: courseRating,
      slopeRating: slopeRating,
    ).toFirestore());
    return doc.id;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Stream of the current user's active round (null if none).
  static Stream<Round?> activeRoundStream() {
    return _col
        .where('userId', isEqualTo: _uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          final rounds = snap.docs.map(Round.fromFirestore).toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
          return rounds.first;
        });
  }

  /// Stream of the last [limit] completed rounds for the current user.
  static Stream<List<Round>> recentRoundsStream({int limit = 10}) {
    return _col
        .where('userId', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) {
          final rounds = snap.docs.map(Round.fromFirestore).toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
          return rounds.take(limit).toList();
        });
  }

  /// Stream of ALL completed rounds — used for stat calculations.
  static Stream<List<Round>> allCompletedRoundsStream() {
    return _col
        .where('userId', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) {
          final rounds = snap.docs.map(Round.fromFirestore).toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
          return rounds;
        });
  }

  // ── Update ────────────────────────────────────────────────────────────────

  /// Saves (upserts) a single hole score inside the round document.
  static Future<void> saveHoleScore(String roundId, HoleScore hs) async {
    final ref = _col.doc(roundId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final round = Round.fromFirestore(snap);
    final updated = List<HoleScore>.from(round.scores);

    final idx = updated.indexWhere((h) => h.hole == hs.hole);
    if (idx >= 0) {
      updated[idx] = hs; // update existing
    } else {
      updated.add(hs);   // new hole
    }
    // Sort so holes stay in order
    updated.sort((a, b) => a.hole.compareTo(b.hole));

    await ref.update({
      'scores': updated.map((h) => h.toMap()).toList(),
    });
  }

  /// Marks the round as completed and records completedAt timestamp.
  static Future<void> completeRound(String roundId) async {
    await _col.doc(roundId).update({
      'status': RoundStatus.completed.name,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Abandons (deletes) an active round.
  static Future<void> abandonRound(String roundId) async {
    await _col.doc(roundId).delete();
  }

  /// Permanently deletes a completed round.
  static Future<void> deleteRound(String roundId) async {
    await _col.doc(roundId).delete();
  }
}
