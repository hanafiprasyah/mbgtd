import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollPeriod {
  final String id;
  final DateTime resetAt;
  final int grandTotal;
  final Map<String, int> teamTotal;
  final Map<String, Map<String, dynamic>> volunteers;

  PayrollPeriod({
    required this.id,
    required this.resetAt,
    required this.grandTotal,
    required this.teamTotal,
    required this.volunteers,
  });

  factory PayrollPeriod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayrollPeriod(
      id: doc.id,
      resetAt: (data['resetAt'] as Timestamp).toDate(),
      grandTotal: data['grandTotal'] ?? 0,
      teamTotal: Map<String, int>.from(data['teamTotal'] ?? {}),
      volunteers: Map<String, Map<String, dynamic>>.from(
        data['volunteers'] ?? {},
      ),
    );
  }
}
