import 'package:flutter/material.dart';
import 'package:mbg_test/core/helper/design_system.dart';

Widget buildMenuCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 1, end: 1),
    duration: const Duration(milliseconds: 120),
    builder: (context, scale, child) {
      return Transform.scale(scale: scale, child: child);
    },
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        onTap: () async {
          // Tap animation effect
          await Future.delayed(const Duration(milliseconds: 40));
          onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.grey.shade900, Colors.grey.shade800]
                  : [
                      Theme.of(context).primaryColor.withValues(alpha: 0.15),
                      Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: Theme.of(context).primaryColor),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
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
