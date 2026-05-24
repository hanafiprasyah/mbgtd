import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_state.dart';

class PayrollDetailPage extends StatefulWidget {
  final String id;
  const PayrollDetailPage({super.key, required this.id});

  @override
  State<PayrollDetailPage> createState() => _PayrollDetailPageState();
}

class _PayrollDetailPageState extends State<PayrollDetailPage> {
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
      case 'OCBC NISP':
        return 'assets/ocbc_nisp.png';
      case 'CIMB NIAGA':
        return 'assets/cimb_niaga.png';
      case 'Maybank':
        return 'assets/maybank.png';
      default:
        return 'assets/default_bank.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! String) {
      return const Scaffold(
        body: Center(child: Text('Volunteer ID tidak ditemukan')),
      );
    }

    final volunteerId = args;
    context.read<VolunteerBloc>().add(GetVolunteerById(volunteerId));
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Detail')),
      body: _buildBody(volunteerId),
    );
  }

  Widget _buildBody(String id) {
    return BlocBuilder<VolunteerBloc, VolunteerState>(
      builder: (context, state) {
        if (state is VolunteerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is VolunteerDetailLoaded) {
          final volunteer = state.volunteer;

          final nama = volunteer.namaLengkap;
          final namaBank = volunteer.namaBank ?? '-';
          final noRek = volunteer.noRek ?? '-';

          final logo = getBankAsset(namaBank);

          return Column(
            children: [
              _buildHeader(context, nama, namaBank, noRek, logo),

              // PIC TOGGLE
              SwitchListTile(
                title: const Text('Jadikan sebagai PIC'),
                subtitle: const Text(
                  'PIC mendapatkan tambahan Rp 10.000 / scan',
                ),
                value: volunteer.isPIC,
                onChanged: (value) {
                  if (value == true) {
                    context.read<VolunteerBloc>().add(
                      ToggleVolunteerPIC(
                        volunteer.id,
                        volunteer.isPIC,
                        volunteer.tim,
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              // SALARY INFO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Gaji',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        volunteer.isPIC
                            ? 'Status: PIC (+Rp 10.000 / scan)'
                            : 'Status: Non-PIC (Gaji default)',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        if (state is VolunteerError) {
          return Center(child: Text(state.message));
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String nama,
    String namaBank,
    String noRek,
    String logo,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          // LOGO BANK
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              logo,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: Colors.white24,
                child: const Icon(Icons.account_balance, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  namaBank.isNotEmpty ? '$namaBank • $noRek' : 'Unregistered',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
