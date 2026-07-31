import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/helper/design_system.dart';

Widget buildModernInfoCard(
  BuildContext context,
  User user,
  String formatDate,
  String relativeTime,
) {
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
          "ACCOUNT INFORMATION",
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _modernTile(
              context,
              Icons.email_outlined,
              "Email",
              user.email ?? "-",
              cs.primary,
            ),
            _modernDivider(cs),
            _modernTile(
              context,
              Icons.calendar_today_rounded,
              "Created",
              formatDate,
              cs.secondary,
            ),
            _modernDivider(cs),
            _modernTile(
              context,
              Icons.access_time_rounded,
              "Last Login",
              relativeTime,
              cs.tertiary,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _modernDivider(ColorScheme cs) {
  return Divider(
    height: 1,
    indent: 68,
    endIndent: AppSpacing.md,
    color: cs.outlineVariant.withValues(alpha: 0.3),
  );
}

Widget _modernTile(
  BuildContext context,
  IconData icon,
  String title,
  String value,
  Color accent,
) {
  final cs = Theme.of(context).colorScheme;

  return Padding(
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
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
