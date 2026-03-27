import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stats_service.dart';

class FriendProfile {
  final String uid;
  final String displayName;
  final String email;
  String? avatarUrl;
  /// 'pending_sent' | 'pending_received' | 'accepted'
  final String status;
  final DateTime addedAt;

  // Populated separately for leaderboard / detail screen
  AppStats? stats;
  int? totalRounds;

  FriendProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.status,
    required this.addedAt,
    this.stats,
    this.totalRounds,
  });

  factory FriendProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return FriendProfile(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Golfer',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      status: data['status'] as String? ?? 'accepted',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'status': status,
        'addedAt': Timestamp.fromDate(addedAt),
      };
}
