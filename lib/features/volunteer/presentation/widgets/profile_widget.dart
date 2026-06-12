import 'package:flutter/material.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';
import 'package:mbg_test/features/volunteer/presentation/widgets/chip.dart';

class VolunteerAvatar extends StatelessWidget {
  const VolunteerAvatar({super.key, required this.volunteer});

  final Volunteer volunteer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = volunteer.isActive;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          volunteer.namaLengkap.trim().isNotEmpty
              ? volunteer.namaLengkap.trim()[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class VolunteerSummary extends StatelessWidget {
  const VolunteerSummary({super.key, required this.volunteer});

  final Volunteer volunteer;

  int _hitungUmur(DateTime tanggalLahir) {
    final now = DateTime.now();
    int umur = now.year - tanggalLahir.year;
    if (now.month < tanggalLahir.month ||
        (now.month == tanggalLahir.month && now.day < tanggalLahir.day)) {
      umur--;
    }
    return umur;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          volunteer.namaLengkap,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            VolunteerMetaChip(
              icon: Icons.cake_outlined,
              label: '${_hitungUmur(volunteer.tanggalLahir)} Tahun',
            ),
            VolunteerMetaChip(
              icon: Icons.badge_outlined,
              label: volunteer.jenisKelamin,
            ),
          ],
        ),
      ],
    );
  }
}
