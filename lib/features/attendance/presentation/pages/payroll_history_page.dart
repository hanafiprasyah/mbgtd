import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PayrollHistoryPage extends StatefulWidget {
  const PayrollHistoryPage({super.key});

  @override
  State<PayrollHistoryPage> createState() => _PayrollHistoryPageState();
}

class _PayrollHistoryPageState extends State<PayrollHistoryPage> {
  bool showHistory = false;

  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  Stream<QuerySnapshot> _getPeriods() {
    return FirebaseFirestore.instance
        .collection('attendance_periods')
        .orderBy('resetAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Period History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  showHistory = !showHistory;
                });
              },
              child: Text(showHistory ? 'Hide History' : 'Show History'),
            ),
          ),

          if (showHistory)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getPeriods(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('No period history found'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      final resetAt = (data['resetAt'] as Timestamp).toDate();
                      final totalDeleted = data['totalDeleted'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(dateFormatter.format(resetAt)),
                          subtitle: Text('Total reset: $totalDeleted data'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
