import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;
  static DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(_uid);

  static Stream<double?> handicapGoalStream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      return (data?['handicapGoal'] as num?)?.toDouble();
    });
  }

  static Future<void> setHandicapGoal(double goal) async {
    await _doc.set({'handicapGoal': goal}, SetOptions(merge: true));
  }

  static Future<void> clearHandicapGoal() async {
    await _doc.update({'handicapGoal': FieldValue.delete()});
  }

  static Stream<String?> avatarUrlStream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return null;
      return snap.data()?['avatarUrl'] as String?;
    });
  }

  static Future<void> setAvatarUrl(String url) async {
    await _doc.set({'avatarUrl': url}, SetOptions(merge: true));
  }

  static Future<void> clearAvatarUrl() async {
    await _doc.update({'avatarUrl': FieldValue.delete()});
  }

  // ── Saved location ────────────────────────────────────────────────────────

  static Future<({double lat, double lng, String label})?> getSavedLocation() async {
    try {
      final snap = await _doc.get();
      if (!snap.exists) return null;
      final data = snap.data();
      final loc = data?['savedLocation'] as Map<String, dynamic>?;
      if (loc == null) return null;
      return (
        lat:   (loc['lat']   as num).toDouble(),
        lng:   (loc['lng']   as num).toDouble(),
        label: loc['label']  as String,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLocation(double lat, double lng, String label) async {
    await _doc.set({
      'savedLocation': {'lat': lat, 'lng': lng, 'label': label},
    }, SetOptions(merge: true));
  }

  static Future<void> clearSavedLocation() async {
    try {
      await _doc.update({'savedLocation': FieldValue.delete()});
    } catch (_) {}
  }
}
