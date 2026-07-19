import 'package:flutter/material.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';
import 'package:mbg_test/features/volunteer/presentation/widgets/profile_widget.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search volunteer...',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear search',
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class FilterActionButton extends StatelessWidget {
  const FilterActionButton({
    super.key,
    required this.count,
    required this.onPressed,
    required this.onLongPress,
  });

  final int count;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: count > 0 ? colorScheme.primary : null,
          ),
          tooltip: 'Filter',
          onPressed: onPressed,
          onLongPress: onLongPress,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class VolunteerTile extends StatelessWidget {
  const VolunteerTile({
    super.key,
    required this.volunteer,
    required this.index,
    required this.onDelete,
    required this.isDeveloper,
  });

  final Volunteer volunteer;
  final int index;
  final VoidCallback onDelete;
  final bool isDeveloper;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final delay = Duration(milliseconds: (index * 40).clamp(0, 320));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + delay.inMilliseconds),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Hero(
          tag: 'volunteer_card_${volunteer.id}',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/volunteer-detail',
                  arguments: volunteer,
                );
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      VolunteerAvatar(volunteer: volunteer),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: VolunteerSummary(volunteer: volunteer)),
                      IconButton(
                        icon: Icon(
                          Icons.qr_code_rounded,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Generate QR',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/qr-generator',
                            arguments: volunteer,
                          );
                        },
                      ),

                      if (isDeveloper)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error,
                          ),
                          tooltip: 'Delete',
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
