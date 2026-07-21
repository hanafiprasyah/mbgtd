import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/services/camera_prewarm.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_payroll_repository.dart';
import 'package:mbg_test/features/attendance/presentation/pages/qr_generator_page.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_sp_history_model.dart';
import 'package:mbg_test/features/volunteer/data/repositories/volunteer_repository.dart';

/// Self-service dashboard shown to a logged-in volunteer with no admin-type
/// role (developer/admin/accountant/sppi/aslap/nutritionist).
///
/// Shows, in realtime:
///  - total scan count
///  - total salary (calculated with the exact same rules as admin payroll)
///  - a timeline of every attendance date, with type (full/half/absent)
///  - SP (Surat Peringatan / warning) history
///
/// A volunteer whose role is "scanner" or "admin" gets an extra QR scan
/// action in the header. A volunteer who is "aslap" and/or "admin" also
/// sees a "Quick Actions" card linking to volunteer management and/or food
/// bank management — these used to be full menu-grid destinations, but
/// aslap/admin are otherwise plain volunteers, so they now land on this
/// same personal dashboard with just those extra shortcuts attached.
class VolunteerDashboard extends StatefulWidget {
  final String authUid;
  final String greeting;
  final String fullname;
  final bool isScanner;
  final bool canManageVolunteers;
  final bool canManageFoodBank;

  const VolunteerDashboard({
    super.key,
    required this.authUid,
    required this.greeting,
    required this.fullname,
    this.isScanner = false,
    this.canManageVolunteers = false,
    this.canManageFoodBank = false,
  });

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  // Kept as reassignable (not `late final`) fields so a failed stream can be
  // retried from the UI without recreating the whole widget — reassigning
  // and calling setState() resubscribes the relevant StreamBuilder only.
  late Stream<Map<String, dynamic>> _dashboardStream;
  late Stream<List<VolunteerSpHistory>> _spHistoryStream;

  // Caps the reading width on tablets/desktop so text and cards don't
  // stretch edge-to-edge on wide screens.
  static const double _maxContentWidth = 680.0;

  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _dashboardStream = AttendancePayrollRepository().getMyDashboardStream(
      widget.authUid,
    );
    _spHistoryStream = VolunteerRepository().getMySPHistory(widget.authUid);
  }

  void _retrySpHistory() {
    setState(() {
      _spHistoryStream = VolunteerRepository().getMySPHistory(widget.authUid);
    });
  }

  Future<void> _handleRefresh() async {
    setState(_initStreams);
    // Give the freshly-subscribed streams a brief moment so the pull-to
    // -refresh indicator doesn't vanish before the first snapshot arrives.
    await Future.delayed(const Duration(milliseconds: 450));
  }

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

  /// True once today's date shows up in the timeline with an actual scan
  /// (i.e. not an end-of-day "absent" entry). Timeline dates are stored as
  /// `yyyy-MM-dd`, matching what [_formatDate] parses.
  bool _hasScannedToday(List<Map<String, dynamic>> timeline) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return timeline.any((item) {
      final date = (item['date'] ?? '').toString();
      final attendanceType = (item['attendanceType'] ?? 'full').toString();
      return date == todayKey && attendanceType != 'absent';
    });
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
    return StreamBuilder<Map<String, dynamic>>(
      stream: _dashboardStream,
      builder: (context, snapshot) {
        String stateKey;
        Widget body;

        if (snapshot.hasError) {
          stateKey = 'error';
          body = _buildErrorState(
            context,
            message: "Failed to load your dashboard. Please try again.",
            onRetry: () => setState(_initStreams),
          );
        } else if (!snapshot.hasData) {
          stateKey = 'loading';
          body = _buildLoadingSkeleton(context);
        } else if (snapshot.data!['linked'] != true) {
          stateKey = 'not-linked';
          body = _buildNotLinkedState(context);
        } else {
          stateKey = 'content';
          body = _buildContent(context, snapshot.data!);
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(key: ValueKey(stateKey), child: body),
        );
      },
    );
  }

  // ── Top-level states ────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(height: 13, width: 110),
          const SizedBox(height: 8),
          const _SkeletonBox(height: 24, width: 170),
          const SizedBox(height: AppSpacing.md),
          _SkeletonBox(height: 150, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: AppSpacing.xl),
          const _SkeletonBox(height: 15, width: 150),
          const SizedBox(height: 12),
          _SkeletonBox(height: 96, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: AppSpacing.xl),
          const _SkeletonBox(height: 15, width: 170),
          const SizedBox(height: 12),
          _SkeletonBox(height: 64, borderRadius: BorderRadius.circular(14)),
          const SizedBox(height: 10),
          _SkeletonBox(height: 64, borderRadius: BorderRadius.circular(14)),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 48),
            Icon(Icons.cloud_off_rounded, size: 40, color: colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineError(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 18, color: colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: colorScheme.error, fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildNotLinkedState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 48),
            Icon(Icons.link_off_rounded, size: 48, color: colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            const Text(
              "Your account isn't linked to a volunteer record yet.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "Please contact your admin to link your account.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTimelineState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 36, color: colorScheme.outline),
          const SizedBox(height: 10),
          Text(
            "No attendance recorded yet.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Your scan history will show up here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.outline, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Main content ────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final totalScan = data['totalScan'] ?? 0;
    final effectiveScan = data['effectiveScan'];
    final totalGaji = data['totalGaji'] ?? 0;
    final timeline = (data['timeline'] as List).cast<Map<String, dynamic>>();
    // Realtime, not a snapshot-in-time flag: this is recomputed from the
    // live `timeline` on every stream event, so the moment a scanner
    // records today's attendance the banner disappears on its own — there
    // is no manual dismiss action for it.
    final hasScannedToday = _hasScannedToday(timeline);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderRow(context, data),
                        if (!hasScannedToday) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildAttendanceWarningBanner(context),
                        ],
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
              ),
              if (widget.canManageVolunteers || widget.canManageFoodBank)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.md,
                      0,
                    ),
                    child: _FadeSlideIn(
                      delay: const Duration(milliseconds: 70),
                      child: _buildQuickActionsSection(context),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.md,
                    0,
                  ),
                  child: _FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: StreamBuilder<List<VolunteerSpHistory>>(
                      stream: _spHistoryStream,
                      builder: (context, spSnapshot) {
                        return _buildSPSection(context, spSnapshot);
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: _FadeSlideIn(
                    delay: const Duration(milliseconds: 210),
                    child: _buildTimelineHeader(context, timeline.length),
                  ),
                ),
              ),
              if (timeline.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyTimelineState(context))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverList.builder(
                    itemCount: timeline.length,
                    itemBuilder: (context, index) {
                      final item = timeline[index];
                      final isLast = index == timeline.length - 1;
                      return _TileEntrance(
                        child: _buildTimelineTile(
                          context,
                          item,
                          isLast: isLast,
                        ),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  /// Greeting + quick actions. Name is wrapped in `Expanded` with an
  /// ellipsis so a long full name never pushes the action buttons off
  /// screen or triggers a RenderFlex overflow on narrow devices.
  Widget _buildHeaderRow(BuildContext context, Map<String, dynamic> data) {
    final colorScheme = Theme.of(context).colorScheme;
    final id = (data['id'] ?? '').toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              ),
              const SizedBox(height: 2),
              Text(
                widget.fullname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isScanner) ...[
              _buildActionButton(
                context,
                icon: Icons.qr_code_scanner_rounded,
                tooltip: 'Scan Attendance',
                onPressed: () {
                  CameraPrewarmService.warmBeforeNavigate();
                  Navigator.pushNamed(context, '/qr-scanner');
                },
              ),
              const SizedBox(width: 8),
            ],
            _buildActionButton(
              context,
              icon: Icons.qr_code_rounded,
              tooltip: 'Generate QR',
              onPressed: id.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrGeneratorPage(
                            id: id,
                            nama: (data['nama'] ?? widget.fullname).toString(),
                            tim: (data['tim'] ?? '').toString(),
                          ),
                        ),
                      );
                    },
            ),
          ],
        ),
      ],
    );
  }

  /// Shared style for the header's icon actions (QR generate / QR scan) —
  /// dims the icon when [onPressed] is null so it's obvious the action
  /// isn't available yet (e.g. id still loading).
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final tint = enabled ? colorScheme.primary : colorScheme.outline;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: IconButton(
        icon: Icon(icon, color: tint),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  /// Non-dismissible warning shown when the volunteer hasn't had their QR
  /// scanned yet today. There's intentionally no close/dismiss action —
  /// [_buildContent] only renders this while `_hasScannedToday` is false,
  /// so it clears itself the instant a scanner records today's attendance
  /// (the dashboard stream is realtime).
  Widget _buildAttendanceWarningBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade600, Colors.red.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _PulsingIcon(icon: Icons.warning_amber_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "You haven't scanned attendance today",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Ask a scanner to scan your QR code to record it.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            Color.lerp(colorScheme.primary, Colors.black, 0.22)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Salary",
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: child,
              ),
            ),
            child: Text(
              _currencyFormatter.format(totalGaji),
              key: ValueKey(totalGaji),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  label: "Total Scan",
                  value: "$totalScan",
                ),
              ),
              Container(
                width: 1,
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: colorScheme.onPrimary.withValues(alpha: 0.18),
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
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onPrimary.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Shortcut list for volunteers who also carry a light admin capability
  /// (aslap → volunteer management, admin → food bank management — both
  /// still land on this personal dashboard rather than the full menu grid).
  /// Renders nothing structurally different when empty; the sliver that
  /// calls this is only built when at least one capability is enabled.
  Widget _buildQuickActionsSection(BuildContext context) {
    final tiles = <Widget>[];

    if (widget.canManageVolunteers) {
      tiles.add(
        _buildQuickActionTile(
          context,
          icon: Icons.people_rounded,
          title: 'Volunteers',
          subtitle: 'Manage volunteer records',
          onTap: () => Navigator.pushNamed(context, '/volunteers'),
        ),
      );
    }

    if (widget.canManageFoodBank) {
      if (tiles.isNotEmpty) {
        tiles.add(
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        );
      }
      tiles.add(
        _buildQuickActionTile(
          context,
          icon: Icons.food_bank_rounded,
          title: 'Food Bank',
          subtitle: 'Manage menu archive',
          onTap: () => Navigator.pushNamed(context, '/food-bank'),
        ),
      );
    }

    return _buildSectionCard(
      context,
      title: "Quick Actions",
      icon: Icons.apps_rounded,
      child: Column(children: tiles),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Groups a titled block of content into a rounded, tonal card — gives
  /// the dashboard's sections clear visual separation instead of running
  /// straight into each other.
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ],
      ),
    );
  }

  // ── SP (Surat Peringatan / warning) history ─────────────────────────────

  Widget _buildSPSection(
    BuildContext context,
    AsyncSnapshot<List<VolunteerSpHistory>> spSnapshot,
  ) {
    Widget sectionChild;

    if (spSnapshot.connectionState == ConnectionState.waiting) {
      sectionChild = Column(
        key: const ValueKey('sp-loading'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(height: 44, borderRadius: BorderRadius.circular(12)),
          const SizedBox(height: 10),
          _SkeletonBox(height: 44, borderRadius: BorderRadius.circular(12)),
        ],
      );
    } else if (spSnapshot.hasError) {
      debugPrint("Error loading SP history: ${spSnapshot.error}");
      sectionChild = KeyedSubtree(
        key: const ValueKey('sp-error'),
        child: _buildInlineError(
          context,
          message: "Failed to load your SP history.",
          onRetry: _retrySpHistory,
        ),
      );
    } else {
      final spHistory = spSnapshot.data ?? [];
      // History is newest-first, so the latest entry's newLevel is the
      // volunteer's current SP status.
      final currentLevel = spHistory.isNotEmpty ? spHistory.first.newLevel : 0;

      sectionChild = Column(
        key: const ValueKey('sp-content'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  _TileEntrance(
                    child: _buildSPTimelineTile(
                      context,
                      spHistory[i],
                      isLast: i == spHistory.length - 1,
                    ),
                  ),
              ],
            ),
        ],
      );
    }

    return _buildSectionCard(
      context,
      title: "SP Warning History",
      icon: Icons.warning_amber_rounded,
      child: sectionChild,
    );
  }

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
          Expanded(
            child: Text(
              "No warnings on record.",
              style: TextStyle(color: colorScheme.outline, fontSize: 13),
            ),
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
          // the attendance timeline below.
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(width: 8),
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

  // ── Attendance timeline ──────────────────────────────────────────────────

  Widget _buildTimelineHeader(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.timeline_rounded, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "Attendance Timeline",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count",
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  if (scannedByEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Scanned by $scannedByEmail",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

/// Fades and slides its [child] up into place once, on first build. Used
/// for a section's entrance so the dashboard doesn't just pop onto screen —
/// a lightweight touch matching the "fade + slide" transition guidance,
/// without a heavy animation stack.
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Cheap per-tile reveal used for list rows (timeline / SP history). Since
/// list items are only built lazily as they scroll into view, this animates
/// each tile exactly once, right when it first appears — no shared
/// controller bookkeeping needed even for long lists.
class _TileEntrance extends StatelessWidget {
  final Widget child;

  const _TileEntrance({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}

/// A gently pulsing placeholder block used while first-load data is still
/// in flight — gives loading states a clear, modern "skeleton" look instead
/// of a single spinner floating in empty space.
class _SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const _SkeletonBox({required this.height, this.width, this.borderRadius});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 0.85,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: base.withValues(alpha: _opacity.value * 0.08),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Gently breathing icon badge used to draw the eye to the non-dismissible
/// attendance warning without being distracting — a slow, subtle scale
/// pulse rather than anything flashy.
class _PulsingIcon extends StatefulWidget {
  final IconData icon;

  const _PulsingIcon({required this.icon});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1.08,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, color: Colors.white, size: 20),
      ),
    );
  }
}
