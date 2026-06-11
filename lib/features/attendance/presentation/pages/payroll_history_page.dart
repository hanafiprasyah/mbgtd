import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:mbg_test/features/attendance/data/models/payroll_period_model.dart';

class PayrollHistoryPage extends StatefulWidget {
  const PayrollHistoryPage({super.key});

  @override
  State<PayrollHistoryPage> createState() => _PayrollHistoryPageState();
}

class _PayrollHistoryPageState extends State<PayrollHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Period History')),
      body: FutureBuilder<List<PayrollPeriod>>(
        future: _fetchPayrollPeriods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final periods = snapshot.data!;
          if (periods.isEmpty) {
            return const Center(child: Text('No payroll history found.'));
          }
          return ListView.builder(
            itemCount: periods.length,
            itemBuilder: (context, index) {
              final period = periods[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(period.resetAt),
                  ),
                  subtitle: Text(
                    'Total Payroll: ${_formatCurrency(period.grandTotal)}',
                  ),
                  children: [
                    // Show based on team
                    for (var entry in period.teamTotal.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${entry.key}:'),
                            Text(_formatCurrency(entry.value)),
                          ],
                        ),
                      ),
                    const Divider(),
                    // Show volunteer (expandable)
                    for (var volunteerEntry in period.volunteers.entries)
                      ListTile(
                        title: Text(volunteerEntry.value['nama']),
                        subtitle: Text(
                          '${volunteerEntry.value['tim']} - ${_formatCurrency(volunteerEntry.value['totalGaji'])}',
                        ),
                        onTap: () {
                          _showVolunteerDetail(context, volunteerEntry.value);
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<PayrollPeriod>> _fetchPayrollPeriods() async {
    final snap = await FirebaseFirestore.instance
        .collection('payroll_periods')
        .orderBy('resetAt', descending: true)
        .get();
    return snap.docs.map((doc) => PayrollPeriod.fromFirestore(doc)).toList();
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _showVolunteerDetail(
    BuildContext context,
    Map<String, dynamic> volunteer,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                volunteer['nama'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Team: ${volunteer['tim']}'),
              Text('Total Payroll: ${_formatCurrency(volunteer['totalGaji'])}'),
              const SizedBox(height: 12),
              const Text(
                'Daily Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(volunteer['dailyDetails'] as List).map((day) {
                final multiplier = day['multiplier'].toDouble();
                String type;
                if (multiplier == 0) {
                  type = 'Absent';
                } else if (multiplier == 0.5) {
                  type = 'Half Day / Sakit';
                } else {
                  type = 'Full Day';
                }
                return ListTile(
                  title: Text(day['date']),
                  subtitle: Text('$type (multiplier $multiplier)'),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
