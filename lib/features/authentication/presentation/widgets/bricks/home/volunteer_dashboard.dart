import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_payroll_repository.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_sp_history_model.dart';
import 'package:mbg_test/features/volunteer/data/repositories/volunteer_repository.dart';

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
                  ],
                ),
              ),
            ),
            StreamBuilder<List<VolunteerSpHistory>>(
              stream: VolunteerRepository().getMySPHistory(authUid),
              builder: (context, spSnapshot) {
                if (spSnapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (spSnapshot.hasError) {
                  debugPrint("Error loading SP history: ${spSnapshot.error}");
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        "Failed to load your SP history.",
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  );
                }

                final spHistory = spSnapshot.data ?? [];
                // History is newest-first, so the latest entry's newLevel
                // is the volunteer's current SP status.
                final currentLevel = spHistory.isNotEmpty
                    ? spHistory.first.newLevel
                    : 0;

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SP Warning History",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (currentLevel > 0) ...[
                          _buildSPStatusBanner(context, currentLevel),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (spHistory.isEmpty)
                          _buildSPEmptyState(context)
                        else
                          Column(
                            children: [
                              for (int i = 0; i < spHistory.length; i++)
                                _buildSPTimelineTile(
                                  context,
                                  spHistory[i],
                                  isLast: i == spHistory.length - 1,
                                ),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

  // ── SP (Surat Peringatan / warning) history ─────────────────────────────

  Color _spColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFFFBC02D); // yellow — SP 1
      case 2:
        return const Color(0xFFFF9800); // orange — SP 2
      case 3:
        return const Color(0xFFF44336); // red — SP 3
      default:
        return Colors.grey;
    }
  }

  Widget _buildSPStatusBanner(BuildContext context, int level) {
    final color = _spColor(level);
    final isSuspended = level >= 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isSuspended ? Icons.block : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSuspended
                  ? "You currently have an active SP 3 warning and your account is suspended."
                  : "You currently have an active SP $level warning.",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSPEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, size: 18, color: colorScheme.outline),
          const SizedBox(width: 8),
          Text(
            "No warnings on record.",
            style: TextStyle(color: colorScheme.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSPTimelineTile(
    BuildContext context,
    VolunteerSpHistory entry, {
    required bool isLast,
  }) {
    final isUndo = entry.action == SpAction.undo;
    final color = isUndo
        ? Theme.of(context).colorScheme.primary
        : _spColor(entry.newLevel);
    final title = isUndo
        ? "Undo — SP ${entry.previousLevel} cleared"
        : "SP ${entry.newLevel} Warning Issued";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail: dot + connecting line — same visual language as
          // the attendance timeline above.
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUndo ? Icons.undo : Icons.warning_amber_rounded,
                  size: 16,
                  color: color,
                ),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: color,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(entry.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (entry.reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.reason,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  if ((entry.performedBy ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "By ${entry.performedBy}",
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
