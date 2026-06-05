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
  final isDeveloper = user != null && role.toLowerCase().contains('developer');
  final isScanner = user != null && role.toLowerCase().contains('scanner');
  final isAccountant =
      user != null && role.toLowerCase().contains('accountant');
  final isSPPI = user != null && role.toLowerCase().contains('sppi');
  final isAslap = user != null && role.toLowerCase().contains('aslap');
  final isAdmin = user != null && role.toLowerCase().contains('admin');

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
              children: [
                if (isScanner) ...[
                  // ONLY Scan menu for scanner/security role
                  MenuCard(
                    index: 0,
                    icon: Icons.qr_code_scanner,
                    title: "Scan",
                    subtitle: "Attendance",
                    onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
                  ),
                ] else if (isAccountant) ...[
                  // ONLY Payroll & Reports menu for accountants
                  MenuCard(
                    index: 0,
                    icon: Icons.payments,
                    title: "Payroll",
                    subtitle: "Salary & Period",
                    onTap: () => Navigator.pushNamed(context, '/payroll'),
                  ),

                  MenuCard(
                    index: 3,
                    icon: Icons.bar_chart,
                    title: "Reports",
                    subtitle: "Coming soon",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 1),
                          content: Text('Reports feature coming soon!'),
                        ),
                      );
                    },
                  ),
                ] else if (isAslap) ...[
                  // ONLY Volunteer and Payroll menu for ASLAP
                  MenuCard(
                    index: 0,
                    icon: Icons.people,
                    title: "Volunteers",
                    subtitle: "Manage Volunteer",
                    onTap: () => Navigator.pushNamed(context, '/volunteers'),
                  ),

                  MenuCard(
                    index: 1,
                    icon: Icons.payments,
                    title: "Payroll",
                    subtitle: "Salary & Period",
                    onTap: () => Navigator.pushNamed(context, '/payroll'),
                  ),
                ] else if (isSPPI) ...[
                  // ONLY Scanner menu is not include for SPPI
                  MenuCard(
                    index: 0,
                    icon: Icons.people,
                    title: "Volunteers",
                    subtitle: "Manage Volunteer",
                    onTap: () => Navigator.pushNamed(context, '/volunteers'),
                  ),

                  MenuCard(
                    index: 1,
                    icon: Icons.payments,
                    title: "Payroll",
                    subtitle: "Salary & Period",
                    onTap: () => Navigator.pushNamed(context, '/payroll'),
                  ),

                  MenuCard(
                    index: 3,
                    icon: Icons.bar_chart,
                    title: "Reports",
                    subtitle: "Coming soon",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 1),
                          content: Text('Reports feature coming soon!'),
                        ),
                      );
                    },
                  ),
                ] else if (isAdmin) ...[
                  MenuCard(
                    index: 0,
                    icon: Icons.people,
                    title: "Volunteers",
                    subtitle: "Manage Volunteer",
                    onTap: () => Navigator.pushNamed(context, '/volunteers'),
                  ),
                  MenuCard(
                    index: 2,
                    icon: Icons.qr_code_scanner,
                    title: "Scan",
                    subtitle: "Attendance",
                    onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
                  ),
                ] else if (isDeveloper) ...[
                  // Full access for developer role
                  MenuCard(
                    index: 0,
                    icon: Icons.people,
                    title: "Volunteers",
                    subtitle: "Manage Volunteer",
                    onTap: () => Navigator.pushNamed(context, '/volunteers'),
                  ),
                  MenuCard(
                    index: 1,
                    icon: Icons.payments,
                    title: "Payroll",
                    subtitle: "Salary & Period",
                    onTap: () => Navigator.pushNamed(context, '/payroll'),
                  ),
                  MenuCard(
                    index: 2,
                    icon: Icons.qr_code_scanner,
                    title: "Scan",
                    subtitle: "Attendance",
                    onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
                  ),
                  MenuCard(
                    index: 3,
                    icon: Icons.bar_chart,
                    title: "Reports",
                    subtitle: "Coming soon",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          duration: Duration(seconds: 1),
                          content: Text('Reports feature coming soon!'),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  Center(child: Text('No menu available for your role.')),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
