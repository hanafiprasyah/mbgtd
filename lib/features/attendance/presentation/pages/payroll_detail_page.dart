import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_state.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_payroll_repository.dart';
import 'package:mbg_test/core/helper/salary_calculator.dart';

class PayrollDetailPage extends StatefulWidget {
  final String id;
  const PayrollDetailPage({super.key, required this.id});

  @override
  State<PayrollDetailPage> createState() => _PayrollDetailPageState();
}

class _PayrollDetailPageState extends State<PayrollDetailPage> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );
  final AttendancePayrollRepository payrollRepository =
      AttendancePayrollRepository();
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
        body: Center(child: Text('Volunteer ID not found')),
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

          return StreamBuilder<Map<String, dynamic>>(
            stream: payrollRepository.getPayrollStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final payrollMap = snapshot.data!;
              final payrollData = payrollMap[id];

              final totalScan = payrollData?['totalScan'] ?? 0;
              final tim = (volunteer.tim).toString().trim();
              final isPIC = volunteer.isPIC == true;

              const picBonusPerScan = 10000;
              final baseSalary = calculateSalary(totalScan, tim);
              final totalGaji = isPIC
                  ? baseSalary + (totalScan * picBonusPerScan)
                  : baseSalary;

              return Column(
                children: [
                  _buildHeader(context, nama, namaBank, noRek, logo),

                  const SizedBox(height: 16),

                  // SALARY INFO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payments_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Salary Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // STATUS BADGE
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPIC
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isPIC ? 'PIC (+Rp 10.000 / scan)' : 'Non-PIC',
                              style: TextStyle(
                                color: isPIC ? Colors.green : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // TOTAL SCAN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Scan',
                                style: TextStyle(fontSize: 13),
                              ),
                              Text(
                                '$totalScan time(s)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isPIC) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Bonus (PIC)',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  currencyFormatter.format(totalScan * 10000),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Calculated from total scans × Rp 10.000',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          // BASE SALARY
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Base Salary',
                                style: TextStyle(fontSize: 13),
                              ),
                              Text(
                                currencyFormatter.format(baseSalary),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          // TOTAL GAJI
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Salary',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currencyFormatter.format(totalGaji),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  namaBank.isNotEmpty ? '$namaBank • $noRek' : 'Unregistered',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
