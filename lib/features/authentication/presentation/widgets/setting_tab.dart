import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/authentication/presentation/widgets/bricks/setting/info_card.dart';
import 'package:mbg_test/features/authentication/presentation/widgets/bricks/setting/profile_hero.dart';
import 'package:mbg_test/features/authentication/presentation/widgets/bricks/setting/logout_button.dart';

Widget buildSettingTab(
  BuildContext context,
  User? user,
  String formatDate,
  Color avatarColor,
  String relativeTime,
  Map<String, dynamic>? userData,
) {
  final isDeveloper =
      user != null &&
      (userData?['role']?.toLowerCase().contains('developer') ?? false);

  final colorScheme = Theme.of(context).colorScheme;

  return Scaffold(
    backgroundColor: colorScheme.surfaceContainerLowest,
    appBar: AppBar(
      title: const Text("Settings"),
      centerTitle: true,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: colorScheme.surfaceContainerLowest,
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
  final colorScheme = Theme.of(context).colorScheme;

  final actions = <_AdminAction>[
    _AdminAction(
      icon: Icons.manage_accounts_rounded,
      label: "Manage Users",
      subtitle: "View, edit, and remove user accounts",
      color: colorScheme.primary,
      onTapNavigation: () => Navigator.pushNamed(context, '/manage-users'),
    ),
    _AdminAction(
      icon: Icons.volunteer_activism_rounded,
      label: "Add Volunteer Account",
      subtitle: "Create a login for an existing volunteer",
      color: colorScheme.tertiary,
      onTapNavigation: () =>
          Navigator.pushNamed(context, '/volunteer-account-form'),
    ),
    _AdminAction(
      icon: Icons.storefront_rounded,
      label: "Manage Kitchens",
      subtitle: "Configure kitchens across the program",
      color: colorScheme.secondary,
      onTapNavigation: () => Navigator.pushNamed(context, '/manage-kitchens'),
    ),
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            "ADMIN TOOLS",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                _AdminActionTile(action: actions[i]),
                if (i != actions.length - 1)
                  Divider(
                    height: 1,
                    indent: 68,
                    endIndent: AppSpacing.md,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _AdminAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTapNavigation;

  const _AdminAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTapNavigation,
  });
}

class _AdminActionTile extends StatefulWidget {
  final _AdminAction action;

  const _AdminActionTile({required this.action});

  @override
  State<_AdminActionTile> createState() => _AdminActionTileState();
}

class _AdminActionTileState extends State<_AdminActionTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final action = widget.action;

    return InkWell(
      onTap: action.onTapNavigation,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _pressed
            ? colorScheme.onSurface.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
