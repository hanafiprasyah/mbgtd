import 'package:flutter/material.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/attendance/presentation/pages/payroll_page.dart';
import 'package:mbg_test/features/attendance/presentation/pages/scanner_page.dart';
import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeTab extends StatelessWidget {
  final User? user;
  const HomeTab({super.key, required this.user});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 15) return "Good afternoon";
    if (hour < 18) return "Good evening";
    return "Good night";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_getGreeting()}, ${user?.email ?? 'User'}!",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              child: const Text('Go to volunteer list'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VolunteerListPage()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              child: const Text('Go to volunteer payroll'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PayrollPage()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              child: const Text('Go to attendance scanner'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScannerPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
