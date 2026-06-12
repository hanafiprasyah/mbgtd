import 'package:flutter/material.dart';

class VolunteerMetaChip extends StatelessWidget {
  const VolunteerMetaChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.selectedTim,
    required this.selectedGender,
    required this.onRemoveTim,
    required this.onRemoveGender,
  });

  final String? selectedTim;
  final String? selectedGender;
  final VoidCallback onRemoveTim;
  final VoidCallback onRemoveGender;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (selectedTim != null)
            Chip(
              label: Text('Tim: $selectedTim'),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              backgroundColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
              onDeleted: onRemoveTim,
            ),
          if (selectedGender != null)
            Chip(
              label: Text('Gender: $selectedGender'),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              backgroundColor: colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
              onDeleted: onRemoveGender,
            ),
        ],
      ),
    );
  }
}
