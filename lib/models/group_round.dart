import 'package:cloud_firestore/cloud_firestore.dart';

class GroupRoundPlayer {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  /// 'invited' | 'joined' | 'declined' | 'completed'
  final String status;
  final String? roundId;
  final int? totalScore;
  final double? scoreDiff;

  const GroupRoundPlayer({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    required this.status,
    this.roundId,
    this.totalScore,
    this.scoreDiff,
  });

  factory GroupRoundPlayer.fromMap(String uid, Map<String, dynamic> data) {
    return GroupRoundPlayer(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Golfer',
      avatarUrl: data['avatarUrl'] as String?,
      status: data['status'] as String? ?? 'invited',
      roundId: data['roundId'] as String?,
      totalScore: (data['totalScore'] as num?)?.toInt(),
      scoreDiff: (data['scoreDiff'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'status': status,
        if (roundId != null) 'roundId': roundId,
        if (totalScore != null) 'totalScore': totalScore,
        if (scoreDiff != null) 'scoreDiff': scoreDiff,
      };
}

class GroupRound {
  final String id;
  final String hostUid;
  final String hostName;
  final String courseName;
  final String courseLocation;
  final int totalHoles;
  final double? courseRating;
  final int? slopeRating;
  final DateTime createdAt;
  /// 'waiting' | 'active' | 'completed'
  final String status;
  final Map<String, GroupRoundPlayer> players;

  const GroupRound({
    required this.id,
    required this.hostUid,
    required this.hostName,
    required this.courseName,
    required this.courseLocation,
    required this.totalHoles,
    this.courseRating,
    this.slopeRating,
    required this.createdAt,
    required this.status,
    required this.players,
  });

  factory GroupRound.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawPlayers = (d['players'] as Map<String, dynamic>?) ?? {};
    final players = rawPlayers.map(
      (uid, val) => MapEntry(
        uid,
        GroupRoundPlayer.fromMap(uid, val as Map<String, dynamic>),
      ),
    );
    return GroupRound(
      id: doc.id,
      hostUid: d['hostUid'] as String,
      hostName: d['hostName'] as String? ?? 'Golfer',
      courseName: d['courseName'] as String,
      courseLocation: d['courseLocation'] as String? ?? '',
      totalHoles: (d['totalHoles'] as num).toInt(),
      courseRating: (d['courseRating'] as num?)?.toDouble(),
      slopeRating: (d['slopeRating'] as num?)?.toInt(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      status: d['status'] as String? ?? 'waiting',
      players: players,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hostUid': hostUid,
        'hostName': hostName,
        'courseName': courseName,
        'courseLocation': courseLocation,
        'totalHoles': totalHoles,
        if (courseRating != null) 'courseRating': courseRating,
        if (slopeRating != null) 'slopeRating': slopeRating,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
        'players': players.map((uid, p) => MapEntry(uid, p.toMap())),
      };
}
