import 'package:cloud_firestore/cloud_firestore.dart';

enum PracticeType { range, chipping, putting, onCourse }

extension PracticeTypeLabel on PracticeType {
  String get label {
    switch (this) {
      case PracticeType.range:    return 'Range';
      case PracticeType.chipping: return 'Chipping';
      case PracticeType.putting:  return 'Putting';
      case PracticeType.onCourse: return 'On Course';
    }
  }
}

class PracticeSession {
  final String? id;
  final String userId;
  final DateTime date;
  final PracticeType type;
  final int? balls;
  final int? durationMinutes;
  final String? notes;

  const PracticeSession({
    this.id,
    required this.userId,
    required this.date,
    required this.type,
    this.balls,
    this.durationMinutes,
    this.notes,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'type': type.name,
        if (balls != null) 'balls': balls,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  factory PracticeSession.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PracticeSession(
      id: doc.id,
      userId: d['userId'] as String,
      date: (d['date'] as Timestamp).toDate(),
      type: PracticeType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => PracticeType.range,
      ),
      balls: (d['balls'] as num?)?.toInt(),
      durationMinutes: (d['durationMinutes'] as num?)?.toInt(),
      notes: d['notes'] as String?,
    );
  }
}
