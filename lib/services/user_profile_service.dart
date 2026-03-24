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
}
