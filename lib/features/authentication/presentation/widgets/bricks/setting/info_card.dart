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

  return Container(
    decoration: BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      children: [
        _modernTile(context, Icons.email_outlined, "Email", user.email ?? "-"),
        _modernDivider(),
        _modernTile(context, Icons.calendar_today, "Created", formatDate),
        _modernDivider(),
        _modernTile(context, Icons.access_time, "Last Login", relativeTime),
      ],
    ),
  );
}

Widget _modernDivider() {
  return const Divider(height: 1, indent: 16, endIndent: 16);
}

Widget _modernTile(
  BuildContext context,
  IconData icon,
  String title,
  String value,
) {
  final cs = Theme.of(context).colorScheme;

  return Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
