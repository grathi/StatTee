import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_round.dart';
import '../models/friend_profile.dart';
import '../services/friends_service.dart';
import 'golf_course_api_service.dart';

class GroupRoundService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  // ── Create session ──────────────────────────────────────────────────────────

  /// Creates a group round session. Returns the sessionId.
  /// The host's own player entry is set to 'joined' immediately.
  /// Invited friends are set to 'invited' — the Cloud Function watches for
  /// these and sends FCM push notifications.
  static Future<String> createSession({
    required String courseName,
    required String courseLocation,
    required int totalHoles,
    double? courseRating,
    int? slopeRating,
    List<GolfApiHole> holes = const [],
    required List<FriendProfile> invitees,
  }) async {
    final me = _auth.currentUser!;
    final myAvatar = await FriendsService.fetchAvatarUrl(_uid);

    final players = <String, GroupRoundPlayer>{
      // Host is already joined
      _uid: GroupRoundPlayer(
        uid: _uid,
        displayName: me.displayName ?? 'Golfer',
        avatarUrl: myAvatar,
        status: 'joined',
      ),
    };

    for (final f in invitees) {
      players[f.uid] = GroupRoundPlayer(
        uid: f.uid,
        displayName: f.displayName,
        avatarUrl: f.avatarUrl,
        status: 'invited',
      );
    }

    final session = GroupRound(
      id: '',
      hostUid: _uid,
      hostName: me.displayName ?? 'Golfer',
      courseName: courseName,
      courseLocation: courseLocation,
      totalHoles: totalHoles,
      courseRating: courseRating,
      slopeRating: slopeRating,
      holes: holes,
      createdAt: DateTime.now(),
      status: 'waiting',
      players: players,
    );

    final doc = await _db.collection('groupRounds').add(session.toFirestore());
    return doc.id;
  }

  // ── Join session (invitee accepts) ─────────────────────────────────────────

  /// Called when an invited friend accepts. Links their roundId to the session.
  static Future<void> joinSession(String sessionId, String roundId) async {
    await _db.collection('groupRounds').doc(sessionId).update({
      'players.$_uid.status': 'joined',
      'players.$_uid.roundId': roundId,
      'status': 'active',
    });
  }

  // ── Cancel session (host abandons their round) ─────────────────────────────

  /// Called when the host exits the scorecard before finishing.
  /// Marks the session as 'cancelled' so invitees know not to join.
  static Future<void> cancelSession(String sessionId) async {
    await _db.collection('groupRounds').doc(sessionId).update({
      'status': 'cancelled',
    });
  }

  // ── Decline invite ─────────────────────────────────────────────────────────

  static Future<void> declineInvite(String sessionId) async {
    await _db.collection('groupRounds').doc(sessionId).update({
      'players.$_uid.status': 'declined',
    });
  }

  // ── Report completion ──────────────────────────────────────────────────────

  /// Called when a player finishes their round. Writes score + checks if all done.
  static Future<void> reportCompletion(
    String sessionId, {
    required String roundId,
    required int totalScore,
    required double scoreDiff,
  }) async {
    final ref = _db.collection('groupRounds').doc(sessionId);

    await ref.update({
      'players.$_uid.status': 'completed',
      'players.$_uid.roundId': roundId,
      'players.$_uid.totalScore': totalScore,
      'players.$_uid.scoreDiff': scoreDiff,
    });

    // Check if all non-declined players have completed
    final snap = await ref.get();
    final session = GroupRound.fromFirestore(snap);
    final active = session.players.values
        .where((p) => p.status != 'declined' && p.status != 'invited');
    final allDone = active.every((p) => p.status == 'completed');
    if (allDone) {
      await ref.update({'status': 'completed'});
    }
  }

  // ── Streams ─────────────────────────────────────────────────────────────────

  static Stream<GroupRound> sessionStream(String sessionId) {
    return _db
        .collection('groupRounds')
        .doc(sessionId)
        .snapshots()
        .map((snap) => GroupRound.fromFirestore(snap));
  }

  /// Pending invites for current user — sessions where their status is 'invited'
  /// and the session itself has not been cancelled.
  static Stream<List<GroupRound>> pendingInvitesStream() {
    return _db
        .collection('groupRounds')
        .where('players.$_uid.status', isEqualTo: 'invited')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GroupRound.fromFirestore(d))
            .where((s) => s.status != 'cancelled' && s.status != 'completed')
            .toList());
  }

  // ── Fetch single session ──────────────────────────────────────────────────

  static Future<GroupRound?> fetchSession(String sessionId) async {
    final doc = await _db.collection('groupRounds').doc(sessionId).get();
    if (!doc.exists) return null;
    return GroupRound.fromFirestore(doc);
  }
}
