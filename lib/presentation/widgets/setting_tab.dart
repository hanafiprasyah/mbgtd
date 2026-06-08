import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/presentation/widgets/bricks/setting/info_card.dart';
import 'package:mbg_test/presentation/widgets/bricks/setting/profile_hero.dart';
import 'package:mbg_test/presentation/widgets/bricks/setting/logout_button.dart';

Widget buildSettingTab(
  BuildContext context,
  User? user,
  String formatDate,
  Color avatarColor,
  String relativeTime,
  Map<String, dynamic>? userData,
) {
  final isDeveloper =
      user != null && userData?['role']?.toLowerCase().contains('developer');

  return Scaffold(
    appBar: AppBar(
      title: const Text("Settings"),
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    body: user == null
        ? const Center(
            child: Text(
              "User not found. Please re-cache by logged out and in again.",
            ),
          )
        : SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: buildProfileHero(
                      context,
                      user,
                      userData?['username'] ?? "Loading username..",
                      userData?['role'] ?? "Loading user role..",
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: buildModernInfoCard(
                      context,
                      user,
                      formatDate,
                      relativeTime,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: isDeveloper ? _userSetting(context) : null,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: buildLogoutButton(context),
                  ),
                ),
              ],
            ),
          ),
  );
}

Widget _userSetting(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/manage-users');
        },
        icon: const Icon(Icons.manage_accounts_rounded),
        label: const Text("Manage Users"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    ),
  );
}
