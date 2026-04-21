import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/join_request.dart';
import '../models/user_session.dart';
import 'places_service.dart';

class NearbyPlayersService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ── Geofencing ────────────────────────────────────────────────────────────

  /// Returns the nearest [GolfCourseDetail] within [radiusMeters] (default 1 km),
  /// or null if no course is close enough.
  static GolfCourseDetail? findNearestCourse(
    double lat,
    double lng,
    List<GolfCourseDetail> courses, {
    double radiusMeters = 1000,
  }) {
    GolfCourseDetail? nearest;
    double nearestDist = double.infinity;

    for (final course in courses) {
      if (course.lat == null || course.lng == null) continue;
      final dist = Geolocator.distanceBetween(lat, lng, course.lat!, course.lng!);
      if (dist < radiusMeters && dist < nearestDist) {
        nearestDist = dist;
        nearest = course;
      }
    }
    return nearest;
  }

  // ── Session write / heartbeat ─────────────────────────────────────────────

  /// Creates or updates the current user's session in `active_sessions/{uid}`.
  /// Reads `hcp` and `fcmToken` from `users/{uid}` so the session is always
  /// in sync with the user's profile.
  static Future<void> upsertSession({
    required String courseId,
    required String courseName,
    required double lat,
    required double lng,
    required bool isLookingForGroup,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};

    final session = UserSession(
      userId: uid,
      displayName: _auth.currentUser?.displayName ?? userData['displayName'] as String? ?? '',
      avatarUrl: userData['avatarUrl'] as String?,
      fcmToken: userData['fcmToken'] as String?,
      hcp: (userData['handicapGoal'] as num?)?.toDouble(),
      currentCourseId: courseId,
      courseName: courseName,
      isLookingForGroup: isLookingForGroup,
      lat: lat,
      lng: lng,
      updatedAt: DateTime.now(),
    );

    await _db
        .collection('active_sessions')
        .doc(uid)
        .set(session.toFirestore(), SetOptions(merge: true));
  }

  // ── Toggle looking-for-group flag only ────────────────────────────────────

  /// Updates only `isLookingForGroup` and refreshes `updatedAt`.
  /// Does not update GPS coords — use [upsertSession] for that.
  static Future<void> setLookingForGroup(bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('active_sessions').doc(uid).update({
      'isLookingForGroup': value,
      'updatedAt': Timestamp.now(),
    });
  }

  // ── Delete own session (check-out) ────────────────────────────────────────

  static Future<void> deleteSession() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('active_sessions').doc(uid).delete();
  }

  // ── Real-time discovery stream ────────────────────────────────────────────

  /// Returns a live stream of players at [courseId] who are looking for a group,
  /// excluding the current user.
  static Stream<List<UserSession>> nearbyPlayersStream(String courseId) {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('active_sessions')
        .where('currentCourseId', isEqualTo: courseId)
        .where('isLookingForGroup', isEqualTo: true)
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserSession.fromFirestore(d.id, d.data()))
            .where((s) => s.userId != uid)
            .toList());
  }

  // ── Restore session state on screen init ──────────────────────────────────

  /// Fetches the current user's session document (if any) so the screen can
  /// restore its check-in state when the user switches back to the Nearby tab.
  static Future<UserSession?> getMySession() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('active_sessions').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserSession.fromFirestore(doc.id, doc.data()!);
  }

  // ── Join request ──────────────────────────────────────────────────────────

  /// Writes a join request to the `joinRequests` collection.
  /// The `onJoinRequest` Cloud Function will send an FCM push to [targetSession.userId].
  /// Returns the new request document ID so the sender can cancel it later.
  static Future<String?> sendJoinRequest({
    required UserSession targetSession,
  }) async {    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};

    final ref = await _db.collection('joinRequests').add({
      'fromUserId': uid,
      'fromDisplayName': _auth.currentUser?.displayName ?? userData['displayName'] ?? '',
      'fromAvatarUrl': userData['avatarUrl'],
      'fromHcp': (userData['handicapGoal'] as num?)?.toDouble(),
      'toUserId': targetSession.userId,
      'courseId': targetSession.currentCourseId,
      'courseName': targetSession.courseName,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
    return ref.id;
  }

  // ── Incoming requests stream ──────────────────────────────────────────────

  /// Real-time stream of pending join requests sent to the current user.
  static Stream<List<JoinRequest>> incomingRequestsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('joinRequests')
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => JoinRequest.fromFirestore(d.id, d.data()))
            .toList());
  }

  // ── Cancel a sent join request ────────────────────────────────────────────

  /// Cancels a pending join request (sets status to 'cancelled').
  /// This unblocks the "Request to Join" button for the sender.
  static Future<void> cancelRequest(String requestId) async {
    await _db.collection('joinRequests').doc(requestId).update({
      'status': 'cancelled',
      'respondedAt': Timestamp.now(),
    });
  }

  /// Returns the request ID for any pending request the current user sent
  /// to [targetUserId], or null if none exists.
  static Future<String?> findPendingOutgoingRequest(String targetUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db
        .collection('joinRequests')
        .where('fromUserId', isEqualTo: uid)
        .where('toUserId', isEqualTo: targetUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  // ── Respond to a join request ─────────────────────────────────────────────

  /// Updates the request status to 'accepted' or 'declined'.
  static Future<void> respondToRequest(String requestId, bool accept) async {
    await _db.collection('joinRequests').doc(requestId).update({
      'status': accept ? 'accepted' : 'declined',
      'respondedAt': Timestamp.now(),
    });
  }
}
