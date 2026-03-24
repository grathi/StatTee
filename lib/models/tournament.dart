import 'package:cloud_firestore/cloud_firestore.dart';

class Tournament {
  final String? id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final List<String> roundIds;

  const Tournament({
    this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    this.roundIds = const [],
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'createdAt': Timestamp.fromDate(createdAt),
        'roundIds': roundIds,
      };

  factory Tournament.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Tournament(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      roundIds: List<String>.from(d['roundIds'] as List? ?? []),
    );
  }

  Tournament copyWith({List<String>? roundIds}) => Tournament(
        id: id,
        userId: userId,
        name: name,
        createdAt: createdAt,
        roundIds: roundIds ?? this.roundIds,
      );
}
