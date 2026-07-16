import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_payroll_repository.dart';

/// Self-service dashboard shown to a logged-in volunteer with no admin-type
/// role (developer/admin/accountant/sppi/aslap/nutritionist/scanner).
///
/// Shows, in realtime:
///  - total scan count
///  - total salary (calculated with the exact same rules as admin payroll)
///  - a timeline of every attendance date, with type (full/half/absent)
class VolunteerDashboard extends StatelessWidget {
  final String authUid;
  final String greeting;
  final String fullname;

  const VolunteerDashboard({
    super.key,
    required this.authUid,
    required this.greeting,
    required this.fullname,
  });

  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  String _formatEffective(dynamic value) {
    final v = value is num ? value.toDouble() : 0.0;
    final formatted = v.toStringAsFixed(2);
    return formatted.endsWith('.00') ? v.toStringAsFixed(0) : formatted;
  }

  String _formatDate(String yyyyMmDd) {
    try {
      final date = DateTime.parse(yyyyMmDd);
      return DateFormat('EEEE, d MMMM yyyy', 'en_US').format(date);
    } catch (_) {
      return yyyyMmDd;
    }
  }

  ({Color color, IconData icon, String label}) _typeVisuals(
    String attendanceType,
    double multiplier,
  ) {
    final isAbsent = attendanceType == 'absent' || multiplier == 0.0;
    if (isAbsent) {
      return (
        color: Colors.redAccent,
        icon: Icons.close_rounded,
        label: 'Absent',
      );
    }
    if (multiplier < 1.0) {
      return (
        color: Colors.orange,
        icon: Icons.access_time_filled_rounded,
        label: 'Half day',
      );
    }
    return (
      color: Colors.green,
      icon: Icons.check_rounded,
      label: 'Full attendance',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<Map<String, dynamic>>(
      stream: AttendancePayrollRepository().getMyDashboardStream(authUid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                "Failed to load your dashboard. Please try again.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final linked = data['linked'] == true;

        if (!linked) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_off_rounded,
                  size: 48,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  "Your account isn't linked to a volunteer record yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "Please contact your admin to link your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final totalScan = data['totalScan'] ?? 0;
        final effectiveScan = data['effectiveScan'];
        final totalGaji = data['totalGaji'] ?? 0;
        final timeline = (data['timeline'] as List)
            .cast<Map<String, dynamic>>();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$greeting, $fullname!",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSummaryCard(
                      context,
                      totalScan: totalScan,
                      effectiveScan: effectiveScan,
                      totalGaji: totalGaji,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      "Attendance timeline",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
            if (timeline.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text("No attendance recorded yet.")),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList.builder(
                  itemCount: timeline.length,
                  itemBuilder: (context, index) {
                    final item = timeline[index];
                    final isLast = index == timeline.length - 1;
                    return _buildTimelineTile(context, item, isLast: isLast);
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required dynamic totalScan,
    required dynamic effectiveScan,
    required dynamic totalGaji,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Salary",
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFormatter.format(totalGaji),
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  context,
                  icon: Icons.qr_code_scanner,
                  label: "Total Scan",
                  value: "$totalScan",
                ),
              ),
              Expanded(
                child: _summaryStat(
                  context,
                  icon: Icons.event_available_rounded,
                  label: "Effective Days",
                  value: _formatEffective(effectiveScan),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: onPrimary.withValues(alpha: 0.8), size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: onPrimary.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTile(
    BuildContext context,
    Map<String, dynamic> item, {
    required bool isLast,
  }) {
    final date = (item['date'] ?? '').toString();
    final attendanceType = (item['attendanceType'] ?? 'full').toString();
    final multiplier = (item['multiplier'] ?? 1.0) as double;
    final note = (item['note'] ?? '').toString();
    final scannedByEmail = (item['scannedByEmail'] ?? '').toString();
    final visuals = _typeVisuals(attendanceType, multiplier);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail: dot + connecting line
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: visuals.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(visuals.icon, size: 16, color: visuals.color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: visuals.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      visuals.label,
                      style: TextStyle(
                        color: visuals.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (note.isNotEmpty && note != 'Full attendance') ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  if (scannedByEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Scanned by $scannedByEmail",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
