import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/practice_session.dart';

class PracticeService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('practice_sessions');

  static Future<void> addSession(PracticeSession session) async {
    await _col.add(session.toFirestore());
  }

  static Stream<List<PracticeSession>> practiceSessionsStream() {
    return _col
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) {
          final sessions = snap.docs.map(PracticeSession.fromFirestore).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return sessions;
        });
  }

  static Future<void> deleteSession(String id) async {
    await _col.doc(id).delete();
  }
}
