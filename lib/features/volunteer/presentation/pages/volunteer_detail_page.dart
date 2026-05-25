import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../bloc/volunteer_bloc.dart';
import '../../bloc/volunteer_event.dart';
import '../../data/models/volunteer_model.dart';
import 'package:mbg_test/core/helper/design_system.dart';

class VolunteerDetailPage extends StatefulWidget {
  const VolunteerDetailPage({super.key});

  @override
  State<VolunteerDetailPage> createState() => _VolunteerDetailPageState();
}

class _VolunteerDetailPageState extends State<VolunteerDetailPage> {
  Volunteer? volunteer;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! Volunteer) {
      return const Scaffold(
        body: Center(child: Text('No volunteer data found')),
      );
    }

    volunteer ??= args;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Volunteer')),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'volunteer-avatar-${volunteer!.namaLengkap}',
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              volunteer!.namaLengkap[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                volunteer!.namaLengkap,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Chip(
                                    label: Text(volunteer!.tim),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.9,
                                    ),
                                    labelStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Info Section
              _buildSectionTitle('Personal Information'),
              _buildInfoCard([
                _buildInfoItem('Address', volunteer!.alamat),
                _buildInfoItem('Gender', volunteer!.jenisKelamin),
                _buildInfoItem(
                  'Birth Date',
                  DateFormat('dd MMM yyyy').format(volunteer!.tanggalLahir),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status'),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey(volunteer!.isActive),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: volunteer!.isActive
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            volunteer!.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: volunteer!.isActive
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bank Info (new)
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                _buildBankInfoItem(
                  context,
                  volunteer!.namaBank ?? '',
                  volunteer!.noRek ?? '',
                ),
              ]),

              const SizedBox(height: AppSpacing.lg),

              // Actions (PRO layout)
              Column(
                children: [
                  // Primary Action
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/volunteer-add',
                          arguments: volunteer,
                        );

                        if (result != null) {
                          setState(() {
                            volunteer = result as Volunteer;
                          });
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Volunteer'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Secondary Actions
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 72,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/qr-generator',
                                arguments: volunteer,
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.qr_code, size: 22),
                                SizedBox(height: 6),
                                Text('QR Code'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SizedBox(
                          height: 72,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final newStatus = !volunteer!.isActive;

                              setState(() {
                                volunteer = volunteer!.copyWith(
                                  isActive: newStatus,
                                );
                              });

                              context.read<VolunteerBloc>().add(
                                ToggleVolunteerStatus(
                                  volunteer!.id,
                                  !newStatus,
                                ),
                              );
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                key: ValueKey(volunteer!.isActive),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    volunteer!.isActive
                                        ? Icons.power_settings_new
                                        : Icons.power_off,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    volunteer!.isActive
                                        ? 'Deactivate'
                                        : 'Activate',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}

Widget _buildInfoCard(List<Widget> children) {
  return Card(
    elevation: AppElevation.low,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(children: children),
    ),
  );
}

Widget _buildInfoItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

Widget _buildBankInfoItem(BuildContext context, String bank, String noRek) {
  String getBankAsset(String bank) {
    switch (bank.toUpperCase()) {
      case 'BCA':
        return 'assets/bca.png';

      case 'BNI':
        return 'assets/bni.png';

      case 'BRI':
        return 'assets/bri.png';

      case 'Mandiri':
        return 'assets/mandiri.png';

      case 'CIMB':
        return 'assets/cimb.png';

      case 'OCBC NISP':
        return 'assets/ocbc_nisp.png';

      case 'Maybank':
        return 'assets/maybank.png';

      default:
        return 'assets/default_bank.png';
    }
  }

  String assetPath = getBankAsset(bank);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Bank Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            assetPath,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Logo not found: $assetPath');
              return Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.account_balance, size: 20),
              );
            },
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        // Bank + Account Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bank.isEmpty ? 'Unregistered' : bank,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                noRek.isEmpty ? 'Unknown' : noRek,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),

        // Copy Button
        IconButton(
          onPressed: noRek.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: noRek));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account number copied')),
                  );
                },
          icon: const Icon(Icons.copy, size: 18),
        ),
      ],
    ),
  );
}
