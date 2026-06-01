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
  final isScanner = user != null && role.toLowerCase().contains('scanner');
  final isAccountant =
      user != null && role.toLowerCase().contains('accountant');

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
                  // ONLY Scan menu for restricted users
                  MenuCard(
                    index: 0,
                    icon: Icons.qr_code_scanner,
                    title: "Scan",
                    subtitle: "Attendance",
                    onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
                  ),
                ] else if (isAccountant) ...[
                  // ONLY Payroll menu for accountants
                  MenuCard(
                    index: 0,
                    icon: Icons.payments,
                    title: "Payroll",
                    subtitle: "Salary & Period",
                    onTap: () => Navigator.pushNamed(context, '/payroll'),
                  ),
                ] else ...[
                  // Full access for other users
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
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
