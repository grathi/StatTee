import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tournament.dart';

class TournamentService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('tournaments');

  static Future<String> createTournament(String name, List<String> roundIds) async {
    final doc = await _col.add(Tournament(
      userId: _uid,
      name: name,
      createdAt: DateTime.now(),
      roundIds: roundIds,
    ).toFirestore());
    return doc.id;
  }

  static Stream<List<Tournament>> tournamentsStream() {
    return _col
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(Tournament.fromFirestore).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  static Future<void> addRound(String tournamentId, String roundId) async {
    final ref  = _col.doc(tournamentId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final t = Tournament.fromFirestore(snap);
    if (t.roundIds.contains(roundId)) return;
    await ref.update({'roundIds': [...t.roundIds, roundId]});
  }

  static Future<void> deleteTournament(String id) async {
    await _col.doc(id).delete();
  }
}
