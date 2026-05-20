import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/presentation/widgets/info_row.dart';
import 'package:mbg_test/presentation/widgets/section_title.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import 'package:mbg_test/core/helper/design_system.dart';

Widget buildSettingTab(
  BuildContext context,
  User? user,
  String formatDate,
  Color avatarColor,
  String relativeTime,
) {
  return Scaffold(
    appBar: AppBar(title: const Text("Settings")),
    body: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: user == null
          ? const Center(child: Text("User not found"))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Email Header
                Center(
                  child: Column(
                    children: [
                      Builder(
                        builder: (_) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  avatarColor.withValues(alpha: 0.7),
                                  avatarColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (user.email != null && user.email!.isNotEmpty)
                                    ? user.email![0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        user.email ?? "-",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 1),
                  duration: const Duration(milliseconds: 150),
                  builder: (context, scale, child) {
                    return Transform.scale(scale: 0.98, child: child);
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () {},
                      child: Builder(
                        builder: (context) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;

                          return Card(
                            elevation: isDark ? 0 : AppElevation.medium,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              side: isDark
                                  ? BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      width: 1,
                                    )
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                children: [
                                  buildSectionTitle("Account"),
                                  buildInfoRow(
                                    icon: Icons.email,
                                    label: "Email",
                                    value: user.email ?? "-",
                                    isCopyable: false,
                                  ),
                                  Divider(
                                    color: Theme.of(context).dividerColor,
                                  ),

                                  buildSectionTitle("Activity"),
                                  buildInfoRow(
                                    icon: Icons.calendar_today,
                                    label: "Created At",
                                    value: formatDate,
                                  ),
                                  Divider(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  buildInfoRow(
                                    icon: Icons.access_time,
                                    label: "Last Sign In",
                                    value: relativeTime,
                                  ),
                                  Divider(
                                    color: Theme.of(context).dividerColor,
                                  ),

                                  buildSectionTitle("Security"),
                                  const SizedBox(height: AppSpacing.xs),
                                  const Text(
                                    "Your account is securely authenticated via Cloudflare and Firebase.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmation'),
                          content: const Text(
                            'Are you sure you want to log out?',
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        context.read<AuthBloc>().add(AuthLoggedOut());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      elevation: AppElevation.high,
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.white),
                        SizedBox(width: AppSpacing.lg),
                        Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}
