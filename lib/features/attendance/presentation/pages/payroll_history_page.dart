import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/features/attendance/data/models/payroll_period_model.dart';
import 'package:intl/date_symbol_data_local.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class PayrollHistoryPage extends StatefulWidget {
  const PayrollHistoryPage({super.key});

  @override
  State<PayrollHistoryPage> createState() => _PayrollHistoryPageState();
}

class _PayrollHistoryPageState extends State<PayrollHistoryPage> {
  late Future<List<PayrollPeriod>> _futurePayrollPeriods;

  @override
  void initState() {
    super.initState();

    _futurePayrollPeriods = _init();
  }

  Future<List<PayrollPeriod>> _init() async {
    await initializeDateFormatting('id_ID');

    return _fetchPayrollPeriods();
  }

  Future<List<PayrollPeriod>> _fetchPayrollPeriods() async {
    final snap = await FirebaseFirestore.instance
        .collection('payroll_periods')
        .orderBy('resetAt', descending: true)
        .get();
    return snap.docs.map((doc) => PayrollPeriod.fromFirestore(doc)).toList();
  }

  void _retry() =>
      setState(() => _futurePayrollPeriods = _fetchPayrollPeriods());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll History')),
      body: FutureBuilder<List<PayrollPeriod>>(
        future: _futurePayrollPeriods,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingView();
          }
          if (snapshot.hasError) {
            return _ErrorView(
              error: snapshot.error.toString(),
              onRetry: _retry,
            );
          }
          final periods = snapshot.data ?? [];
          if (periods.isEmpty) return const _EmptyView();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            itemCount: periods.length,
            itemBuilder: (context, index) =>
                _PeriodCard(period: periods[index]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period Card
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period});

  final PayrollPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        // Remove the default expansion-tile divider lines
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: _DateBadge(date: period.resetAt),
          title: Text(
            DateFormat('dd MMMM yyyy', 'id_ID').format(period.resetAt),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Total: ${_formatCurrency(period.grandTotal)}',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          children: [
            // ── Team totals ──────────────────────────────
            const _SectionLabel(label: 'Team Summary'),
            const SizedBox(height: 6),
            ...period.teamTotal.entries.map(
              (e) => _TeamTotalRow(name: e.key, amount: e.value),
            ),
            const Divider(height: 28),

            // ── Volunteer list ───────────────────────────
            const _SectionLabel(label: 'Volunteer Details'),
            const SizedBox(height: 6),
            ...period.volunteers.entries.map(
              (e) => _VolunteerTile(data: e.value),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Badge
// ─────────────────────────────────────────────────────────────────────────────

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd').format(date),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              height: 1.1,
            ),
          ),
          Text(
            DateFormat('MMM', 'id_ID').format(date).toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.blueAccent,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Team Total Row
// ─────────────────────────────────────────────────────────────────────────────

class _TeamTotalRow extends StatelessWidget {
  const _TeamTotalRow({required this.name, required this.amount});

  final String name;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final color = _teamColor(name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static Color _teamColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('chef')) return Colors.deepOrange;
    if (lower.contains('masak')) return Colors.teal;
    return Colors.blueAccent;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Volunteer Tile
// ─────────────────────────────────────────────────────────────────────────────

class _VolunteerTile extends StatelessWidget {
  const _VolunteerTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final nama = data['nama'] as String? ?? '-';
    final tim = data['tim'] as String? ?? '-';
    final totalGaji = data['totalGaji'] as int? ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showVolunteerDetail(context, data),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            _InitialsAvatar(name: nama),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tim,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              _formatCurrency(totalGaji),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Initials Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});

  final String name;

  String get _initials {
    final parts = name.trim().split(' ');
    return parts.take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
      child: Text(
        _initials.isEmpty ? '?' : _initials,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 1.0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Volunteer Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

void _showVolunteerDetail(
  BuildContext context,
  Map<String, dynamic> volunteer,
) {
  final nama = volunteer['nama'] as String? ?? '-';
  final tim = volunteer['tim'] as String? ?? '-';
  final totalGaji = volunteer['totalGaji'] as int? ?? 0;
  final dailyDetails = volunteer['dailyDetails'] as List? ?? [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tim,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Salary',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          _formatCurrency(totalGaji),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 4),
                const _SectionLabel(label: 'Attendance Details'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Daily detail list
          Expanded(
            child: dailyDetails.isEmpty
                ? Center(
                    child: Text(
                      'No attendance data available.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: dailyDetails.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, index) => _DailyDetailTile(
                      day: dailyDetails[index] as Map<String, dynamic>,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Detail Tile
// ─────────────────────────────────────────────────────────────────────────────

class _DailyDetailTile extends StatelessWidget {
  const _DailyDetailTile({required this.day});

  final Map<String, dynamic> day;

  @override
  Widget build(BuildContext context) {
    final multiplier = (day['multiplier'] as num?)?.toDouble() ?? 0.0;
    final date = day['date'] as String? ?? '-';
    final status = _AttendanceStatus.fromMultiplier(multiplier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              date,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance Status
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceStatus {
  const _AttendanceStatus({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  factory _AttendanceStatus.fromMultiplier(double multiplier) {
    if (multiplier == 0) {
      return _AttendanceStatus(
        label: 'Absent',
        color: Colors.red[700]!,
        backgroundColor: Colors.red.withValues(alpha: 0.06),
        icon: Icons.cancel_outlined,
      );
    } else if (multiplier <= 0.5) {
      return _AttendanceStatus(
        label: 'Half Day',
        color: Colors.orange[700]!,
        backgroundColor: Colors.orange.withValues(alpha: 0.06),
        icon: Icons.timelapse_rounded,
      );
    } else {
      return _AttendanceStatus(
        label: 'Present',
        color: Colors.green[700]!,
        backgroundColor: Colors.green.withValues(alpha: 0.06),
        icon: Icons.check_circle_outline_rounded,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State Views
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.blueAccent),
          SizedBox(height: 12),
          Text(
            'Loading payroll history...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Failed to load data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No payroll history yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Reset payroll periods will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatCurrency(int amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'IDR ',
    decimalDigits: 0,
  ).format(amount);
}
