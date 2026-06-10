import 'package:flutter/material.dart';
import 'package:mbg_test/core/helper/design_system.dart'; // Impor untuk AppRadius, AppElevation

Widget buildReportTab(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Scaffold(
    appBar: AppBar(title: const Text('Report'), centerTitle: true),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppRadius.lg),
        child: Card(
          elevation: AppElevation.medium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(AppRadius.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Large Icon
                Container(
                  padding: const EdgeInsets.all(AppRadius.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.engineering,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppRadius.lg),
                // Title
                Text(
                  'Under Construction',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppRadius.md),
                // Desc
                Text(
                  'We\'re building a powerful report feature with advanced analytics and visualizations.\n'
                  'This complex functionality requires more time to ensure quality and performance.\n\n'
                  'Stay tuned for the upcoming release! 🚀',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppRadius.lg),
                // Progress indicator
                LinearProgressIndicator(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                const SizedBox(height: AppRadius.sm),
                Text(
                  'Estimated release: Q4 2026',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
