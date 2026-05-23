import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:intl/intl.dart';

const Map<String, int> salaryPerTim = {
  'ASLAP': 200000,
  'Chef': 180000,
  'Masak': 145000,
  'Persiapan': 125000,
  'Packing': 125000,
  'Pencucian': 125000,
  'Distribusi': 135000,
  'Satpam': 150000,
};

int calculateSalary(int totalScan, String tim) {
  final salary = salaryPerTim[tim] ?? 0;
  return totalScan * salary;
}

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  String selectedTim = 'all';

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  Stream<Map<String, dynamic>> _getPayrollData() async* {
    final firestore = FirebaseFirestore.instance;

    final volunteersSnap = await firestore.collection('volunteers').get();
    final attendanceSnap = await firestore.collection('attendances').get();

    final Map<String, int> attendanceCount = {};
    final Map<String, String> lastScannedBy = {};

    for (var doc in attendanceSnap.docs) {
      final data = doc.data();
      final volunteerId = data['volunteerId'];

      attendanceCount[volunteerId] = (attendanceCount[volunteerId] ?? 0) + 1;

      // store last scanner email (overwrite = latest)
      if (data['scannedByEmail'] != null) {
        lastScannedBy[volunteerId] = data['scannedByEmail'];
      }
    }

    final Map<String, dynamic> result = {};

    for (var doc in volunteersSnap.docs) {
      final data = doc.data();
      final id = doc.id;

      final totalScan = attendanceCount[id] ?? 0;

      final tim = (data['tim'] ?? '').toString().trim();

      result[id] = {
        'nama': data['namaLengkap'],
        'tim': tim,
        'totalScan': totalScan,
        'totalGaji': calculateSalary(totalScan, tim),
        'scannedByEmail': lastScannedBy[id] ?? '-',
      };
    }

    yield result;
  }

  Future<void> _resetPeriod() async {
    final firestore = FirebaseFirestore.instance;

    final now = DateTime.now();

    final attendanceSnap = await firestore.collection('attendances').get();

    final batch = firestore.batch();

    // Delete all attendance (reset to zero)
    for (var doc in attendanceSnap.docs) {
      batch.delete(doc.reference);
    }

    // Save reset timestamp (tracking period reset)
    final periodRef = firestore.collection('attendance_periods').doc();

    batch.set(periodRef, {
      'resetAt': now,
      'totalDeleted': attendanceSnap.docs.length,
    });

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance reset for new period')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Volunteer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Period',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Period'),
                  content: const Text(
                    'Are you sure you want to reset attendance for a new period?',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _resetPeriod();
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => Navigator.pushNamed(context, '/payroll-history'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: selectedTim,
              decoration: const InputDecoration(
                labelText: 'Filter by Team',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All')),
                ...salaryPerTim.keys.map(
                  (tim) => DropdownMenuItem(
                    value: tim,
                    child: Text(tim.toString().trim()),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedTim = value!;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _getPayrollData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawData = snapshot.data!;

                final data = selectedTim == 'all'
                    ? rawData
                    : Map.fromEntries(
                        rawData.entries.where(
                          (e) => e.value['tim'].toString() == selectedTim,
                        ),
                      );

                if (data.isEmpty) {
                  return const Center(child: Text('No payroll data'));
                }

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data.values.elementAt(index);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: ListTile(
                        title: Text(
                          item['nama'],
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team: ${item['tim']} • ${item['totalScan'] > 0 ? '${item['totalScan']} days' : 'No scan'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scanned by: ${item['scannedByEmail']}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          currencyFormatter.format(item['totalGaji']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
