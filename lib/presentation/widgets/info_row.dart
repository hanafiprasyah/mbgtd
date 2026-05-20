import 'package:flutter/material.dart';
import 'package:mbg_test/core/helper/design_system.dart';

Widget buildInfoRow({
  required IconData icon,
  required String label,
  required String value,
  bool isCopyable = false,
}) {
  return Row(
    children: [
      Icon(icon, size: 20, color: Colors.grey[700]),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
      Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
