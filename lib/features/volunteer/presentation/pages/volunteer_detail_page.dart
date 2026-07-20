import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_payroll_repository.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_sp_history_model.dart';
import 'package:mbg_test/features/volunteer/data/repositories/volunteer_repository.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/volunteer/presentation/widgets/info_widget.dart';

class VolunteerDetailPage extends StatefulWidget {
  const VolunteerDetailPage({super.key});

  @override
  State<VolunteerDetailPage> createState() => _VolunteerDetailPageState();
}

class _VolunteerDetailPageState extends State<VolunteerDetailPage> {
  Volunteer? volunteer;
  final _attendanceRepo = AttendancePayrollRepository();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final colorScheme = Theme.of(context).colorScheme;

    if (args == null || args is! Volunteer) {
      return const Scaffold(
        body: Center(child: Text('No volunteer data found')),
      );
    }

    volunteer ??= args;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Volunteer Detail'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'SP History',
            icon: const Icon(Icons.history_edu_outlined),
            onPressed: () => _showSPHistory(context),
          ),
          IconButton(
            tooltip: 'Attendance History',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _showAttendanceHistory(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Personal Information'),
              buildInfoCard([
                buildInfoItem('Address', volunteer!.alamat),
                buildInfoItem('Gender', volunteer!.jenisKelamin),
                buildInfoItem(
                  'Birth Date',
                  DateFormat('dd MMM yyyy').format(volunteer!.tanggalLahir),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status'),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: Container(
                          key: ValueKey(volunteer!.isActive),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: volunteer!.isActive
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            volunteer!.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: volunteer!.isActive
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Warning Level'),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: Container(
                          key: ValueKey(volunteer!.spLevel),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _spStatusColor(
                              volunteer!.spLevel,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _spStatusLabel(volunteer!.spLevel),
                            style: TextStyle(
                              color: _spStatusColor(volunteer!.spLevel),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                buildBankInfoItem(
                  context,
                  volunteer!.namaBank ?? '',
                  volunteer!.noRek ?? '',
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeaderCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: 'volunteer-avatar-${volunteer!.namaLengkap}',
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                volunteer!.namaLengkap[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  volunteer!.namaLengkap,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Chip(
                  label: Text(volunteer!.tim),
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  labelStyle: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Primary action
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/volunteer-add',
                arguments: volunteer,
              );
              if (result != null) {
                setState(() => volunteer = result as Volunteer);
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Volunteer'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Secondary actions row — equal height, equal width
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SecondaryButton(
                  icon: Icons.qr_code,
                  label: 'QR Code',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/qr-generator',
                    arguments: volunteer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildToggleButton(context)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // SP warning escalation button
        _buildSPButton(context),

        // Undo — only shown once a warning has actually been issued
        if (volunteer!.spLevel > 0) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () => _confirmUndoSP(context, volunteer!.spLevel),
              icon: const Icon(Icons.undo, size: 16),
              label: Text('Undo SP ${volunteer!.spLevel}'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        final newStatus = !volunteer!.isActive;
        setState(() {
          volunteer = volunteer!.copyWith(isActive: newStatus);
        });
        context.read<VolunteerBloc>().add(
          ToggleVolunteerStatus(volunteer!.id, !newStatus),
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Column(
          key: ValueKey(volunteer!.isActive),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              volunteer!.isActive ? Icons.power_settings_new : Icons.power_off,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              volunteer!.isActive ? 'Deactivate' : 'Activate',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── SP (Surat Peringatan / warning) escalation ──────────────────────────

  Widget _buildSPButton(BuildContext context) {
    final level = volunteer!.spLevel;
    final isSuspended = level >= 3;
    final color = _spButtonColor(level);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: isSuspended ? 0.12 : 0.15),
          foregroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.12),
          disabledForegroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
        ),
        onPressed: isSuspended
            ? null
            : () => _confirmEscalateSP(context, level),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Icon(
            isSuspended ? Icons.block : Icons.warning_amber_rounded,
            key: ValueKey(level),
          ),
        ),
        label: Text(
          _spButtonLabel(level),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _confirmEscalateSP(
    BuildContext context,
    int currentLevel,
  ) async {
    final nextLevel = currentLevel + 1;
    final isFinal = nextLevel >= 3;
    final nextColor = _spButtonColor(nextLevel);

    final reason = await _showSPReasonDialog(
      context,
      title: 'Issue SP $nextLevel Warning?',
      description: isFinal
          ? 'This will issue a final SP 3 warning to ${volunteer!.namaLengkap} and automatically deactivate this volunteer. This action cannot be undone from this screen.'
          : 'This will issue an SP $nextLevel warning to ${volunteer!.namaLengkap}.',
      hint: 'e.g. Repeated late arrival without notice',
      confirmLabel: 'Issue SP $nextLevel',
      confirmColor: nextColor,
    );

    if (reason == null || !context.mounted) return;

    context.read<VolunteerBloc>().add(
      EscalateVolunteerSP(
        volunteer!.id,
        currentLevel,
        reason,
        volunteer!.namaLengkap,
      ),
    );

    setState(() {
      volunteer = volunteer!.copyWith(
        spLevel: nextLevel,
        isActive: isFinal ? false : volunteer!.isActive,
      );
    });
  }

  Future<void> _confirmUndoSP(BuildContext context, int currentLevel) async {
    final willReactivate = currentLevel >= 3 && !volunteer!.isActive;

    final reason = await _showSPReasonDialog(
      context,
      title: 'Undo SP $currentLevel?',
      description: willReactivate
          ? 'This clears ${volunteer!.namaLengkap}\'s warning level back to none '
                'and automatically reactivates this volunteer. The current SP '
                '$currentLevel and this undo will both stay on record in the SP '
                'history.'
          : 'This clears ${volunteer!.namaLengkap}\'s warning level back to none. '
                'The current SP $currentLevel and this undo will both stay on record '
                'in the SP history.',
      hint: 'e.g. Warning issued in error / appeal approved',
      confirmLabel: 'Undo SP $currentLevel',
      confirmColor: Theme.of(context).colorScheme.primary,
    );

    if (reason == null || !context.mounted) return;

    context.read<VolunteerBloc>().add(
      ResetVolunteerSP(
        volunteer!.id,
        currentLevel,
        reason,
        volunteer!.namaLengkap,
      ),
    );

    setState(() {
      volunteer = volunteer!.copyWith(
        spLevel: 0,
        isActive: willReactivate ? true : volunteer!.isActive,
      );
    });
  }

  /// Shared dialog for both escalate and undo actions: a short explanation
  /// plus a required reason field. Returns the trimmed reason, or null if
  /// cancelled / left empty.
  Future<String?> _showSPReasonDialog(
    BuildContext context, {
    required String title,
    required String description,
    required String hint,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: hint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'A reason is required'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showAttendanceHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttendanceHistorySheet(
        volunteer: volunteer!,
        repository: _attendanceRepo,
      ),
    );
  }

  void _showSPHistory(BuildContext context) {
    final repository = context.read<VolunteerBloc>().repository;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SPHistorySheet(volunteer: volunteer!, repository: repository),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable secondary button
// ─────────────────────────────────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance History Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

enum _AttendanceStatus { full, half, absent, substituted }

extension _AttendanceStatusX on _AttendanceStatus {
  String get label {
    switch (this) {
      case _AttendanceStatus.full:
        return 'Full Day';
      case _AttendanceStatus.half:
        return 'Half Day';
      case _AttendanceStatus.absent:
        return 'Absent';
      case _AttendanceStatus.substituted:
        return 'Substituted';
    }
  }

  Color get color {
    switch (this) {
      case _AttendanceStatus.full:
        return const Color(0xFF4CAF50);
      case _AttendanceStatus.half:
        return const Color(0xFFFF9800);
      case _AttendanceStatus.absent:
        return const Color(0xFFF44336);
      case _AttendanceStatus.substituted:
        return const Color(0xFF2196F3);
    }
  }

  IconData get icon {
    switch (this) {
      case _AttendanceStatus.full:
        return Icons.check_circle_outline;
      case _AttendanceStatus.half:
        return Icons.timelapse;
      case _AttendanceStatus.absent:
        return Icons.cancel_outlined;
      case _AttendanceStatus.substituted:
        return Icons.swap_horiz;
    }
  }
}

_AttendanceStatus _resolveStatus(Map<String, dynamic> rec) {
  final multiplier = (rec['multiplier'] ?? 1.0) as double;
  final attendanceType = (rec['attendanceType'] ?? 'full').toString();
  final note = (rec['note'] ?? '').toString().trim();

  if (attendanceType == 'absent' || multiplier == 0.0) {
    return _AttendanceStatus.absent;
  } else if (multiplier < 1.0) {
    return _AttendanceStatus.half;
  } else if (multiplier == 1.0 &&
      note.isNotEmpty &&
      note != 'Full attendance') {
    return _AttendanceStatus.substituted;
  }
  return _AttendanceStatus.full;
}

class _AttendanceHistorySheet extends StatelessWidget {
  const _AttendanceHistorySheet({
    required this.volunteer,
    required this.repository,
  });

  final Volunteer volunteer;
  final AttendancePayrollRepository repository;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attendance History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            volunteer.namaLengkap,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              // Stream content
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: repository.getVolunteerAttendanceStream(volunteer.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _buildError(context, snap.error);
                    }
                    final records = snap.data ?? [];
                    if (records.isEmpty) return _buildEmpty(context);
                    return _buildContent(context, records, scrollController);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── States ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 56,
            color: colorScheme.outline.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No attendance records yet',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Failed to load attendance.\n${error ?? ''}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    List<Map<String, dynamic>> records,
    ScrollController scrollController,
  ) {
    // Compute summary stats
    int fullCount = 0, halfCount = 0, absentCount = 0, substitutedCount = 0;
    for (final rec in records) {
      switch (_resolveStatus(rec)) {
        case _AttendanceStatus.full:
          fullCount++;
        case _AttendanceStatus.half:
          halfCount++;
        case _AttendanceStatus.absent:
          absentCount++;
        case _AttendanceStatus.substituted:
          substitutedCount++;
      }
    }

    // Group records by month, preserving sort order (newest first)
    final grouped = <String, List<Map<String, dynamic>>>{};
    final monthOrder = <String>[];
    for (final rec in records) {
      final key = _monthKey(rec['date'] as String);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
        monthOrder.add(key);
      }
      grouped[key]!.add(rec);
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        32,
      ),
      children: [
        _buildStatsStrip(
          context,
          total: records.length,
          full: fullCount,
          half: halfCount,
          absent: absentCount,
          substituted: substitutedCount,
        ),
        const SizedBox(height: 20),
        for (final month in monthOrder) ...[
          _buildMonthHeader(context, month),
          const SizedBox(height: 8),
          _buildMonthTimeline(context, grouped[month]!),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ── Stats strip ────────────────────────────────────────────────────────────

  Widget _buildStatsStrip(
    BuildContext context, {
    required int total,
    required int full,
    required int half,
    required int absent,
    required int substituted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      ('Total', total, colorScheme.primary),
      ('Full', full, const Color(0xFF4CAF50)),
      ('Half', half, const Color(0xFFFF9800)),
      ('Absent', absent, const Color(0xFFF44336)),
      if (substituted > 0) ('Sub', substituted, const Color(0xFF2196F3)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 30,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            _buildStatItem(context, items[i].$1, items[i].$2, items[i].$3),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int value,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ── Month group ────────────────────────────────────────────────────────────

  Widget _buildMonthHeader(BuildContext context, String monthKey) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          monthKey,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthTimeline(
    BuildContext context,
    List<Map<String, dynamic>> records,
  ) {
    return Column(
      children: [
        for (int i = 0; i < records.length; i++)
          _TimelineItem(
            record: records[i],
            isFirst: i == 0,
            isLast: i == records.length - 1,
          ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _monthKey(String dateStr) {
    try {
      return DateFormat('MMMM yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return 'Unknown';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SP (warning) History Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SPHistorySheet extends StatelessWidget {
  const _SPHistorySheet({required this.volunteer, required this.repository});

  final Volunteer volunteer;
  final VolunteerRepository repository;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SP History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            volunteer.namaLengkap,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              // Stream content
              Expanded(
                child: StreamBuilder<List<VolunteerSpHistory>>(
                  stream: repository.getVolunteerSPHistory(volunteer.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _buildError(context, snap.error);
                    }

                    final entries = snap.data ?? [];
                    if (entries.isEmpty) return _buildEmpty(context);
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          _SPHistoryTile(entry: entries[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 56,
            color: colorScheme.outline.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No SP warnings on record',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object? error) {
    debugPrint('$error');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Failed to load SP history.\n${error ?? ''}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

class _SPHistoryTile extends StatelessWidget {
  const _SPHistoryTile({required this.entry});

  final VolunteerSpHistory entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUndo = entry.action == SpAction.undo;
    final color = isUndo ? colorScheme.primary : _spStatusColor(entry.newLevel);
    final title = isUndo
        ? 'Undo — SP ${entry.previousLevel} cleared'
        : 'SP ${entry.newLevel} Warning Issued';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUndo ? Icons.undo : Icons.warning_amber_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(entry.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                if (entry.reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                if ((entry.performedBy ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'By ${entry.performedBy}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline item widget
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.record,
    required this.isFirst,
    required this.isLast,
  });

  final Map<String, dynamic> record;
  final bool isFirst;
  final bool isLast;

  static const double _connectorWidth = 2;
  static const double _dotSize = 12;
  static const double _trackWidth = 32;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = _resolveStatus(record);
    final lineColor = colorScheme.outline.withValues(alpha: 0.25);

    final dateStr = record['date'] as String;
    final note = (record['note'] ?? '').toString().trim();
    final timestampMs = record['timestampMs'] as int?;

    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    final timeStr = timestampMs != null
        ? DateFormat(
            'HH:mm',
          ).format(DateTime.fromMillisecondsSinceEpoch(timestampMs))
        : '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: date column
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date != null ? DateFormat('d').format(date) : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    date != null ? DateFormat('EEE').format(date) : '',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  Text(
                    date != null ? DateFormat('MMM').format(date) : '',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Middle: timeline track
          SizedBox(
            width: _trackWidth,
            child: Column(
              children: [
                // Top connector (hidden for first item in group)
                Container(
                  width: _connectorWidth,
                  height: 20,
                  color: isFirst ? Colors.transparent : lineColor,
                ),
                // Dot
                Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status.color,
                    boxShadow: [
                      BoxShadow(
                        color: status.color.withValues(alpha: 0.35),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Bottom connector (hidden for last item in group)
                Expanded(
                  child: Container(
                    width: _connectorWidth,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),

          // Right: content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: status.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(status.icon, size: 14, color: status.color),
                        const SizedBox(width: 5),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: status.color,
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const Spacer(),
                          Icon(
                            Icons.access_time,
                            size: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (note.isNotEmpty && note != 'Full attendance') ...[
                      const SizedBox(height: 4),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

// SP (warning) status shown in the info card — reflects the volunteer's
// *current* level.
Color _spStatusColor(int level) {
  switch (level) {
    case 1:
      return const Color(0xFFFBC02D); // yellow
    case 2:
      return const Color(0xFFFF9800); // orange
    case 3:
      return const Color(0xFFF44336); // red
    default:
      return Colors.grey;
  }
}

String _spStatusLabel(int level) {
  switch (level) {
    case 1:
      return 'SP 1';
    case 2:
      return 'SP 2';
    case 3:
      return 'SP 3 — Suspended';
    default:
      return 'No Warning';
  }
}

// SP escalation button — colored by the level it currently represents.
// Level 0 → neutral (about to issue SP 1). Level 1 → yellow. Level 2 →
// orange. Level 3 → red and disabled.
Color _spButtonColor(int level) {
  switch (level) {
    case 1:
      return const Color(0xFFFBC02D); // yellow
    case 2:
      return const Color(0xFFFF9800); // orange
    case 3:
      return const Color(0xFFF44336); // red
    default:
      return const Color(0xFF9E9E9E); // neutral grey
  }
}

String _spButtonLabel(int level) {
  switch (level) {
    case 1:
      return 'SP 1 Warning — Escalate to SP 2';
    case 2:
      return 'SP 2 Warning — Escalate to SP 3';
    case 3:
      return 'SP 3 — Volunteer Suspended';
    default:
      return 'Issue SP 1 Warning';
  }
}

Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}
