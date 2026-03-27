import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_profile.dart';
import '../models/round.dart';
import '../services/stats_service.dart';

class FriendsService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  // ── Ensure this user's profile is in Firestore ─────────────────────────────

  /// Called on every app launch. Writes displayName + email so this user
  /// is discoverable by their friends via exact email lookup.
  static Future<void> ensureProfileSynced() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'displayName': user.displayName ?? 'Golfer',
      'email': (user.email ?? '').toLowerCase(),
    }, SetOptions(merge: true));
  }

  // ── Search by exact email ───────────────────────────────────────────────────

  /// Returns the matching user profile, or null if no account found.
  /// Never returns the current user's own profile.
  static Future<FriendProfile?> searchByEmail(String email) async {
    final q = email.trim().toLowerCase();
    if (q.isEmpty) return null;

    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: q)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    if (doc.id == _uid) return null; // don't return self

    // Check if already friends / pending
    final existing = await _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .doc(doc.id)
        .get();

    final status = existing.exists
        ? (existing.data()?['status'] as String? ?? 'accepted')
        : 'none';

    return FriendProfile(
      uid: doc.id,
      displayName: doc.data()['displayName'] as String? ?? 'Golfer',
      email: doc.data()['email'] as String? ?? '',
      avatarUrl: doc.data()['avatarUrl'] as String?,
      status: status,
      addedAt: DateTime.now(),
    );
  }

  // ── Friend request operations ───────────────────────────────────────────────

  static Future<void> sendRequest(FriendProfile target) async {
    final me = _auth.currentUser!;
    final now = DateTime.now();

    // Read the app-set avatar from Firestore (not Firebase Auth photoURL)
    final myDoc = await _db.collection('users').doc(_uid).get();
    final myAvatar = myDoc.data()?['avatarUrl'] as String?;

    final batch = _db.batch();

    // My side: pending_sent
    batch.set(
      _db.collection('users').doc(_uid).collection('friends').doc(target.uid),
      FriendProfile(
        uid: target.uid,
        displayName: target.displayName,
        email: target.email,
        avatarUrl: target.avatarUrl,
        status: 'pending_sent',
        addedAt: now,
      ).toFirestore(),
    );

    // Their side: pending_received
    batch.set(
      _db.collection('users').doc(target.uid).collection('friends').doc(_uid),
      FriendProfile(
        uid: _uid,
        displayName: me.displayName ?? 'Golfer',
        email: (me.email ?? '').toLowerCase(),
        avatarUrl: myAvatar,
        status: 'pending_received',
        addedAt: now,
      ).toFirestore(),
    );

    await batch.commit();
  }

  static Future<void> acceptRequest(String requesterUid) async {
    final batch = _db.batch();
    batch.update(
      _db.collection('users').doc(_uid).collection('friends').doc(requesterUid),
      {'status': 'accepted'},
    );
    batch.update(
      _db.collection('users').doc(requesterUid).collection('friends').doc(_uid),
      {'status': 'accepted'},
    );
    await batch.commit();
  }

  static Future<void> declineOrRemove(String otherUid) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(_uid).collection('friends').doc(otherUid),
    );
    batch.delete(
      _db.collection('users').doc(otherUid).collection('friends').doc(_uid),
    );
    await batch.commit();
  }

  // ── Streams ─────────────────────────────────────────────────────────────────

  static Stream<List<FriendProfile>> friendsStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .snapshots()
        .asyncMap((snap) async {
          final profiles = snap.docs
              .map((d) => FriendProfile.fromFirestore(d.id, d.data()))
              .toList();
          // Fetch fresh avatarUrl from each friend's user doc (not the cached subcollection value)
          for (final p in profiles) {
            final userDoc = await _db.collection('users').doc(p.uid).get();
            p.avatarUrl = userDoc.data()?['avatarUrl'] as String?;
          }
          return profiles;
        });
  }

  static Future<String?> fetchAvatarUrl(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['avatarUrl'] as String?;
  }

  // ── Stats loading ────────────────────────────────────────────────────────────

  static Future<AppStats> loadStatsForUser(String uid) async {
    final snap = await _db
        .collection('rounds')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .get();
    final rounds = snap.docs
        .map((d) => Round.fromFirestore(d))
        .toList();
    return StatsService.calculate(rounds);
  }

  static Future<List<Round>> loadRecentRoundsForUser(String uid,
      {int limit = 5}) async {
    final snap = await _db
        .collection('rounds')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => Round.fromFirestore(d))
        .toList();
  }
}
