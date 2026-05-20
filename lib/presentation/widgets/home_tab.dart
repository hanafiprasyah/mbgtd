import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/presentation/widgets/menu_card.dart';

Widget buildHomeTab(BuildContext context, User? user, String greeting) {
  return Scaffold(
    appBar: AppBar(title: const Text('Home')),
    body: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$greeting, ${user?.email ?? 'User'}!",
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
                buildMenuCard(
                  context,
                  icon: Icons.people,
                  title: "Volunteers",
                  subtitle: "Manage Volunteer",
                  onTap: () => Navigator.pushNamed(context, '/volunteers'),
                ),

                buildMenuCard(
                  context,
                  icon: Icons.payments,
                  title: "Payroll",
                  subtitle: "Salary & Period",
                  onTap: () => Navigator.pushNamed(context, '/payroll'),
                ),

                buildMenuCard(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: "Scan",
                  subtitle: "Attendance",
                  onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
                ),

                buildMenuCard(
                  context,
                  icon: Icons.bar_chart,
                  title: "Reports",
                  subtitle: "Coming soon",
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
