import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Map<String, int> salaryPerTim = {
  'masak': 145000,
  'persiapan': 125000,
  'packing': 125000,
  'pencucian': 125000,
  'distribusi': 130000,
  'satpam': 140000,
};

int calculateSalary(int totalScan, String tim) {
  final normalizedTim = tim.toLowerCase().trim();
  final salary = salaryPerTim[normalizedTim] ?? 0;
  return totalScan * salary;
}

class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

  Stream<Map<String, dynamic>> _getPayrollData() async* {
    final firestore = FirebaseFirestore.instance;

    final volunteersSnap = await firestore.collection('volunteers').get();
    final attendanceSnap = await firestore.collection('attendances').get();

    final Map<String, int> attendanceCount = {};

    for (var doc in attendanceSnap.docs) {
      final volunteerId = doc['volunteerId'];
      attendanceCount[volunteerId] = (attendanceCount[volunteerId] ?? 0) + 1;
    }

    final Map<String, dynamic> result = {};

    for (var doc in volunteersSnap.docs) {
      final data = doc.data();
      final id = doc.id;

      final totalScan = attendanceCount[id] ?? 0;

      final tim = (data['tim'] ?? '').toString().toLowerCase().trim();

      result[id] = {
        'nama': data['namaLengkap'],
        'tim': tim,
        'totalScan': totalScan,
        'totalGaji': calculateSalary(totalScan, tim),
      };
    }

    yield result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Volunteer')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _getPayrollData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(child: Text('No payroll data'));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data.values.elementAt(index);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(item['nama']),
                  subtitle: Text(
                    'Tim: ${item['tim']} • Hadir: ${item['totalScan']}x',
                  ),
                  trailing: Text(
                    'Rp ${item['totalGaji']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
