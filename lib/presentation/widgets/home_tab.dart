import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/presentation/widgets/bricks/home/menu_card.dart';

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

  List<Widget> buildMenus() {
    List<Widget> items = [];

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

    if (isScanner) {
      addMenu(
        index: 0,
        icon: Icons.qr_code_scanner,
        title: 'Scan',
        subtitle: 'Attendance',
        onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
      );
      return items;
    }

    if (isAccountant) {
      addMenu(
        index: 0,
        icon: Icons.payments,
        title: 'Payroll',
        subtitle: 'Salary & Period',
        onTap: () => Navigator.pushNamed(context, '/payroll'),
      );
      addMenu(
        index: 3,
        icon: Icons.bar_chart,
        title: 'Reports',
        subtitle: 'Coming soon',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 1),
            content: Text('Reports feature coming soon!'),
          ),
        ),
      );
      return items;
    }

    if (isAslap) {
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
        index: 3,
        icon: Icons.bar_chart,
        title: 'Reports',
        subtitle: 'Coming soon',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 1),
            content: Text('Reports feature coming soon!'),
          ),
        ),
      );
      return items;
    }

    if (isAdmin) {
      addMenu(
        index: 0,
        icon: Icons.people,
        title: 'Volunteers',
        subtitle: 'Manage Volunteer',
        onTap: () => Navigator.pushNamed(context, '/volunteers'),
      );
      addMenu(
        index: 2,
        icon: Icons.qr_code_scanner,
        title: 'Scan',
        subtitle: 'Attendance',
        onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
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
        index: 3,
        icon: Icons.bar_chart,
        title: 'Reports',
        subtitle: 'Coming soon',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 1),
            content: Text('Reports feature coming soon!'),
          ),
        ),
      );
      return items;
    }

    return [const Center(child: Text('No menu available for your role.'))];
  }

  return Scaffold(
    appBar: AppBar(title: const Text('Home')),
    body: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$greeting, $fullname!",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
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
  );
}
