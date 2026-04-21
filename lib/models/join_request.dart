import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequest {
  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String? fromAvatarUrl;
  final double? fromHcp;
  final String courseName;
  final DateTime createdAt;

  const JoinRequest({
    required this.id,
    required this.fromUserId,
    required this.fromDisplayName,
    this.fromAvatarUrl,
    this.fromHcp,
    required this.courseName,
    required this.createdAt,
  });

  factory JoinRequest.fromFirestore(String id, Map<String, dynamic> d) {
    return JoinRequest(
      id: id,
      fromUserId: d['fromUserId'] as String? ?? '',
      fromDisplayName: d['fromDisplayName'] as String? ?? '',
      fromAvatarUrl: d['fromAvatarUrl'] as String?,
      fromHcp: (d['fromHcp'] as num?)?.toDouble(),
      courseName: d['courseName'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
