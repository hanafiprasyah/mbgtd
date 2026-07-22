import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/authentication/presentation/widgets/bricks/home/menu_card.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_repository.dart';
import 'package:mbg_test/features/authentication/presentation/widgets/bricks/home/volunteer_dashboard.dart';

Widget buildHomeTab(
  BuildContext context,
  User? user,
  String greeting,
  String role,
  String fullname,
) {
  // Determine role-based access
  final isDeveloper = user != null && role.toLowerCase().contains('developer');
  final isScanner = user != null && role.toLowerCase().contains('scanner');
  final isAccountant =
      user != null && role.toLowerCase().contains('accountant');
  final isSPPI = user != null && role.toLowerCase().contains('sppi');
  final isAslap = user != null && role.toLowerCase().contains('aslap');
  final isAdmin = user != null && role.toLowerCase().contains('admin');
  final isNutritionist =
      user != null && role.toLowerCase().contains('nutritionist');

  List<Widget> buildMenus() {
    List<Widget> items = [];

    // generate menu
    void addMenu({
      required int index,
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      items.add(
        MenuCard(
          index: index,
          icon: icon,
          title: title,
          subtitle: subtitle,
          onTap: onTap,
        ),
      );
    }

    if (isNutritionist) {
      addMenu(
        index: 0,
        icon: Icons.people,
        title: 'Volunteers',
        subtitle: 'Manage Volunteer',
        onTap: () => Navigator.pushNamed(context, '/volunteers'),
      );
      addMenu(
        index: 0,
        icon: Icons.food_bank_rounded,
        title: 'Food Bank',
        subtitle: 'Manage menu archive',
        onTap: () => Navigator.pushNamed(context, '/food-bank'),
      );
    }

    if (isAccountant) {
      addMenu(
        index: 0,
        icon: Icons.people,
        title: 'Volunteers',
        subtitle: 'Manage Volunteer',
        onTap: () => Navigator.pushNamed(context, '/volunteers'),
      );
      addMenu(
        index: 0,
        icon: Icons.payments,
        title: 'Payroll',
        subtitle: 'Salary & Period',
        onTap: () => Navigator.pushNamed(context, '/payroll'),
      );
      addMenu(
        index: 0,
        icon: Icons.food_bank_rounded,
        title: 'Food Bank',
        subtitle: 'Manage menu archive',
        onTap: () => Navigator.pushNamed(context, '/food-bank'),
      );
      return items;
    }

    if (isSPPI) {
      addMenu(
        index: 0,
        icon: Icons.people,
        title: 'Volunteers',
        subtitle: 'Manage Volunteer',
        onTap: () => Navigator.pushNamed(context, '/volunteers'),
      );
      addMenu(
        index: 1,
        icon: Icons.payments,
        title: 'Payroll',
        subtitle: 'Salary & Period',
        onTap: () => Navigator.pushNamed(context, '/payroll'),
      );
      addMenu(
        index: 0,
        icon: Icons.food_bank_rounded,
        title: 'Food Bank',
        subtitle: 'Manage menu archive',
        onTap: () => Navigator.pushNamed(context, '/food-bank'),
      );
      return items;
    }

    if (isDeveloper) {
      addMenu(
        index: 0,
        icon: Icons.people,
        title: 'Volunteers',
        subtitle: 'Manage Volunteer',
        onTap: () => Navigator.pushNamed(context, '/volunteers'),
      );
      addMenu(
        index: 1,
        icon: Icons.payments,
        title: 'Payroll',
        subtitle: 'Salary & Period',
        onTap: () => Navigator.pushNamed(context, '/payroll'),
      );
      addMenu(
        index: 2,
        icon: Icons.qr_code_scanner,
        title: 'Scan',
        subtitle: 'Attendance',
        onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
      );
      addMenu(
        index: 0,
        icon: Icons.food_bank_rounded,
        title: 'Food Bank',
        subtitle: 'Manage menu archive',
        onTap: () => Navigator.pushNamed(context, '/food-bank'),
      );
      return items;
    }

    return [const Center(child: Text('No menu available for your role.'))];
  }

  final colorScheme = Theme.of(context).colorScheme;

  // A logged-in user with none of the admin-type roles above is treated as a
  // plain volunteer: instead of an empty menu grid, show their personal
  // realtime dashboard (total scan, attendance timeline, total salary).
  final hasAdminRole = isDeveloper || isAccountant || isSPPI || isNutritionist;

  if (user != null && !hasAdminRole) {
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Home'),
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surfaceContainerLowest,
      ),
      body: VolunteerDashboard(
        authUid: user.uid,
        greeting: greeting,
        fullname: fullname,
        // Admin keeps QR-scan access (like the scanner role); aslap keeps
        // volunteer management; both keep food bank management. These used
        // to be full menu-grid items — now they're quick actions inside the
        // personal dashboard instead.
        isScanner: isScanner || isAdmin,
        canManageVolunteers: isAslap,
        canManageFoodBank: isAslap || isAdmin,
      ),
    );
  }

  return Scaffold(
    backgroundColor: colorScheme.surfaceContainerLowest,
    appBar: AppBar(
      title: const Text('Home'),
      surfaceTintColor: Colors.transparent,
      backgroundColor: colorScheme.surfaceContainerLowest,
    ),
    body: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$greeting, $fullname!",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  children: buildMenus(),
                ),
              ),
            ],
          ),
        ),
        // Floating reminder, cannot be dismissed
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: SafeArea(
            top: false,
            child: _buildAttendanceReminderBanners(context),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAttendanceReminderBanners(BuildContext context) {
  return StreamBuilder<Map<String, List<Map<String, dynamic>>>>(
    stream: AttendanceRepository().getAbsenceReminders(),
    builder: (context, snapshot) {
      // Swallow permission-denied errors that fire during logout, when the
      // auth token is cleared while this stream (kept alive by
      // PersistentTabView's stateManagement) is still attached.
      if (snapshot.hasError) return const SizedBox.shrink();
      if (!snapshot.hasData) return const SizedBox.shrink();

      final notToday = snapshot.data!['notScannedToday'] ?? [];
      final not2Days = snapshot.data!['notScanned2Days'] ?? [];

      if (notToday.isEmpty && not2Days.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          children: [
            if (notToday.isNotEmpty)
              _reminderBanner(
                icon: Icons.schedule_rounded,
                color: Colors.orange,
                text: '${notToday.length} volunteer without attendance today',
                onTap: () =>
                    _showVolunteerListSheet(context, 'Absence Today', notToday),
              ),
            // if (not2Days.isNotEmpty)
            //   _reminderBanner(
            //     icon: Icons.warning_amber_rounded,
            //     color: Colors.redAccent,
            //     text: '${not2Days.length} volunteer without attendance for 2+ days',
            //     onTap: () => _showVolunteerListSheet(
            //       context,
            //       'Absence for 2+ days',
            //       not2Days,
            //     ),
            //   ),
          ],
        ),
      );
    },
  );
}

Widget _reminderBanner({
  required IconData icon,
  required Color color,
  required String text,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showVolunteerListSheet(
  BuildContext context,
  String title,
  List<Map<String, dynamic>> volunteers,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: volunteers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final v = volunteers[i];
                    final daysSince = v['daysSince'] as int?;
                    final subtitle = daysSince == null
                        ? 'Never scanned'
                        : 'Last attendance $daysSince days ago';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          (v['nama'] as String).isNotEmpty
                              ? (v['nama'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                      title: Text(v['nama'] as String),
                      subtitle: Text('${v['tim']} • $subtitle'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
