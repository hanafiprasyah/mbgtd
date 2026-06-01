import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/helper/design_system.dart';

Widget buildProfileHero(
  BuildContext context,
  User user,
  String username,
  String role,
) {
  final cs = Theme.of(context).colorScheme;

  return Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      gradient: LinearGradient(
        colors: [cs.primary, cs.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : "?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Limited Access for $role",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: "Verified",
          child: Icon(Icons.verified_rounded, color: cs.onPrimary),
        ),
      ],
    ),
  );
}
