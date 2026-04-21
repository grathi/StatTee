import 'package:cloud_firestore/cloud_firestore.dart';

class UserSession {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? fcmToken;
  final double? hcp;
  final String currentCourseId;
  final String courseName;
  final bool isLookingForGroup;
  final double lat;
  final double lng;
  final DateTime updatedAt;

  const UserSession({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.fcmToken,
    this.hcp,
    required this.currentCourseId,
    required this.courseName,
    required this.isLookingForGroup,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory UserSession.fromFirestore(String id, Map<String, dynamic> d) {
    return UserSession(
      userId: id,
      displayName: d['displayName'] as String? ?? '',
      avatarUrl: d['avatarUrl'] as String?,
      fcmToken: d['fcmToken'] as String?,
      hcp: (d['hcp'] as num?)?.toDouble(),
      currentCourseId: d['currentCourseId'] as String? ?? '',
      courseName: d['courseName'] as String? ?? '',
      isLookingForGroup: d['isLookingForGroup'] as bool? ?? false,
      lat: (d['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'fcmToken': fcmToken,
        'hcp': hcp,
        'currentCourseId': currentCourseId,
        'courseName': courseName,
        'isLookingForGroup': isLookingForGroup,
        'lat': lat,
        'lng': lng,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
