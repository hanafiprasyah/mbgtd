import 'package:cloud_firestore/cloud_firestore.dart';

class AttendancePeriod {
  final String id;
  final DateTime resetAt;
  final int totalDeleted;

  AttendancePeriod({
    required this.id,
    required this.resetAt,
    required this.totalDeleted,
  });

  factory AttendancePeriod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendancePeriod(
      id: doc.id,
      resetAt: (data['resetAt'] as Timestamp).toDate(),
      totalDeleted: data['totalDeleted'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resetAt': Timestamp.fromDate(resetAt),
      'totalDeleted': totalDeleted,
    };
  }
}
