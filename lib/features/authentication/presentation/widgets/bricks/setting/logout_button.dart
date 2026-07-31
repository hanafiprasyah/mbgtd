import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/authentication/logic/auth/auth_bloc.dart';
import 'package:mbg_test/features/authentication/logic/auth/auth_event.dart';
import 'package:mbg_test/core/helper/design_system.dart';

Widget buildLogoutButton(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          "SESSION",
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.error.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: _LogoutTile(onLogout: () => _handleLogout(context)),
      ),
    ],
  );
}

Future<void> _handleLogout(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmation'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: const Text('I\'m Sure'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    if (context.mounted) {
      GlobalScaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Logging out...'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      context.read<AuthBloc>().add(AuthLoggedOut());
    }
  }
}

class _LogoutTile extends StatefulWidget {
  final VoidCallback onLogout;

  const _LogoutTile({required this.onLogout});

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: widget.onLogout,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _pressed ? cs.error.withValues(alpha: 0.06) : Colors.transparent,
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
                color: cs.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.logout_rounded, color: cs.error, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Logout",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Sign out of your account",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.error.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
