import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_state.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_payroll_repository.dart';
import 'package:mbg_test/core/helper/salary_calculator.dart';
import 'package:rxdart/rxdart.dart';

class PayrollDetailPage extends StatefulWidget {
  final String id;
  const PayrollDetailPage({super.key, required this.id});

  @override
  State<PayrollDetailPage> createState() => _PayrollDetailPageState();
}

class _PayrollDetailPageState extends State<PayrollDetailPage>
    with SingleTickerProviderStateMixin {
  final AttendancePayrollRepository payrollRepository =
      AttendancePayrollRepository();
  bool _hasRequestedVolunteer = false;
  // Animation fields
  late AnimationController _animController;
  late Animation<double> _fadeAttendance;
  late Animation<Offset> _slideAttendance;
  late Animation<double> _fadePool;
  late Animation<Offset> _slidePool;
  late Animation<double> _fadeSalary;
  late Animation<Offset> _slideSalary;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Attendance (muncul duluan)
    _fadeAttendance = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );

    _slideAttendance = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_fadeAttendance);

    // Pool
    _fadePool = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );

    _slidePool = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_fadePool);

    // Salary
    _fadeSalary = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    _slideSalary = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_fadeSalary);

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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

  String formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _getAttendanceNote(dynamic item) {
    if (item is! Map) return '';

    return (item['note'] ??
            item['notes'] ??
            item['reason'] ??
            item['keterangan'] ??
            '')
        .toString()
        .trim();
  }

  String _resolveVolunteerId(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) return args;

    return widget.id;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasRequestedVolunteer) return;

    final volunteerId = _resolveVolunteerId(context);
    if (volunteerId.isEmpty) return;

    _hasRequestedVolunteer = true;
    context.read<VolunteerBloc>().add(GetVolunteerById(volunteerId));
  }

  Map<String, dynamic> _calculatePoolInfo(
    String volunteerTeam,
    Map<String, Map<String, dynamic>> teamDaySummary,
  ) {
    double totalPool = 0.0;
    final List<Map<String, dynamic>> poolEntries = [];

    // Filter for this volunteer's team and find pool contributions
    teamDaySummary.forEach((key, summary) {
      final tim = summary['tim'] as String;
      final date = summary['date'] as String;

      // Check if this entry is for the volunteer's team
      if (tim.toLowerCase() == volunteerTeam.toLowerCase()) {
        // Use generic poolExtra field (supports Chef→Masak, ASLAP→ASLAP, shared teams, etc.)
        final poolExtra = summary['poolExtra'] as double? ?? 0.0;
        if (poolExtra > 0) {
          // Add pool for this date (poolExtra is per fulltime worker)
          totalPool += poolExtra;
          poolEntries.add({'date': date, 'amount': poolExtra});
        }
      }
    });

    // Determine pool source based on volunteer's team
    String poolSource = '';
    if (volunteerTeam.toLowerCase() == 'masak') {
      poolSource = 'Chef'; // Masak receives from Chef
    } else if (volunteerTeam.toLowerCase() == 'aslap') {
      poolSource = 'ASLAP'; // ASLAP receives from itself
    } else {
      poolSource = volunteerTeam; // Other teams show their own team as source
    }

    return {'total': totalPool, 'entries': poolEntries, 'source': poolSource};
  }

  Widget _buildPoolSection(
    BuildContext context,
    Map<String, dynamic> poolInfo,
    String volunteerTeam,
  ) {
    final totalPool = poolInfo['total'] as double;
    final entries = poolInfo['entries'] as List<Map<String, dynamic>>;
    final poolSource = poolInfo['source'] as String;

    final poolTitle = '$poolSource Pool Distribution';
    final infoMessage = totalPool > 0
        ? '$poolSource halfday/absent allocation from shared payroll pool'
        : 'This team does not receive $poolSource pool contributions';
    final noPoolMessage = 'No $poolSource pool allocation for this period';
    final totalLabel = 'Total $poolSource Pool';

    return FadeTransition(
      opacity: _fadePool,
      child: SlideTransition(
        position: _slidePool,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: totalPool > 0
                  ? Colors.purple.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: totalPool > 0
                    ? Colors.purple.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: totalPool > 0 ? Colors.purple : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      poolTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: totalPool > 0
                        ? Colors.purple.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: totalPool > 0 ? Colors.purple : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          infoMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: totalPool > 0
                                ? Colors.purple.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalPool > 0) ...[
                  const SizedBox(height: 12),
                  // Pool entries
                  ...entries.map((entry) {
                    final date = entry['date'] as String;
                    final amount = entry['amount'] as double;
                    final formatted = formatDate(date);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatted,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            currencyFormatter.format(amount.toInt()),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        totalLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(totalPool.toInt()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      noPoolMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final volunteerId = _resolveVolunteerId(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (volunteerId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Volunteer ID not found')),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Payroll Detail'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
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
            stream: Rx.combineLatest2(
              payrollRepository.getPayrollStream(),
              payrollRepository.getTeamDaySummaryStream(),
              (
                Map<String, dynamic> payrollMap,
                Map<String, Map<String, dynamic>> teamDaySummary,
              ) {
                return {
                  'payroll': payrollMap,
                  'teamDaySummary': teamDaySummary,
                };
              },
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final combined = snapshot.data!;
              final payrollMap = combined['payroll'] as Map<String, dynamic>;
              final teamDaySummary =
                  combined['teamDaySummary']
                      as Map<String, Map<String, dynamic>>;

              final payrollData = payrollMap[id];
              final List<dynamic> halfDayDates =
                  payrollData?['halfDayDates'] ?? [];
              final List<dynamic> absentDates =
                  payrollData?['absentDates'] ?? [];

              final totalScan = payrollData?['totalScan'] ?? 0;
              final totalEffectiveScan =
                  (payrollData?['effectiveScan'] ?? 0.0) as num;

              final tim = (volunteer.tim).toString().trim();
              final isPIC = volunteer.isPIC == true;

              const picBonusPerScan = 10000;
              final baseSalary = getBaseSalary(tim);

              // Prefer repository-calculated totalGaji if available
              int totalGaji = (payrollData?['totalGaji'] ?? 0) as int;
              if (totalGaji == 0) {
                final attendancePay = (baseSalary * totalEffectiveScan).toInt();
                final scanBonus =
                    (totalEffectiveScan.toDouble() * picBonusPerScan).toInt();
                totalGaji = isPIC ? attendancePay + scanBonus : attendancePay;
              }

              // Calculate pool distribution for this volunteer's team
              final poolInfo = _calculatePoolInfo(tim, teamDaySummary);
              final isPoolProvider =
                  tim.toLowerCase() == 'chef' || tim.toLowerCase() == 'aslap';

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context, nama, namaBank, noRek, logo),
                    const SizedBox(height: 8),
                    // ATTENDANCE DETAIL INFO
                    FadeTransition(
                      opacity: _fadeAttendance,
                      child: SlideTransition(
                        position: _slideAttendance,
                        child: Padding(
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
                                      Icons.fact_check_rounded,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Attendance Detail',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // EFFECTIVE SCAN
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Effective Attendance',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    Text(
                                      ((totalEffectiveScan))
                                          .toDouble()
                                          .toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),

                                if (halfDayDates.isNotEmpty) ...[
                                  const SizedBox(height: 12),

                                  const Text(
                                    'Half Day Attendance Dates',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  SizedBox(
                                    width: double.infinity,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: halfDayDates.map((item) {
                                        final date = item is Map
                                            ? item['date']
                                            : item;
                                        final note = _getAttendanceNote(item);
                                        final formatted = formatDate(date);

                                        return InkWell(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () {
                                            if (!mounted) return;
                                            _showModalAttendance(
                                              context,
                                              note,
                                              formatted,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text("📅 "),
                                                Text(
                                                  formatted,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.orange.shade800,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (note
                                                    .toString()
                                                    .isNotEmpty) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.touch_app,
                                                    size: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],

                                if (absentDates.isNotEmpty) ...[
                                  const SizedBox(height: 12),

                                  const Text(
                                    'Absent Attendance Dates',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  SizedBox(
                                    width: double.infinity,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: absentDates.map((item) {
                                        final date = item is Map
                                            ? item['date']
                                            : item;
                                        final note = _getAttendanceNote(item);
                                        final formatted = formatDate(date);

                                        return InkWell(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () {
                                            if (!mounted) return;
                                            _showModalAttendance(
                                              context,
                                              note,
                                              formatted,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.red.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text("📅 "),
                                                Text(
                                                  formatted,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.red.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (note
                                                    .toString()
                                                    .isNotEmpty) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.touch_app,
                                                    size: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // POOL DISTRIBUTION (show for all teams except pool providers like Chef & ASLAP)
                    if (!isPoolProvider)
                      _buildPoolSection(context, poolInfo, tim),

                    if (!isPoolProvider) const SizedBox(height: 16),

                    // SALARY INFO
                    FadeTransition(
                      opacity: _fadeSalary,
                      child: SlideTransition(
                        position: _slideSalary,
                        child: Padding(
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
                                    isPIC
                                        ? 'PIC (+Rp 10.000 / scan)'
                                        : 'Non-PIC',
                                    style: TextStyle(
                                      color: isPIC
                                          ? Colors.green
                                          : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // TOTAL SCAN
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Bonus (PIC)',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        currencyFormatter.format(
                                          (totalEffectiveScan.toDouble() *
                                                  10000)
                                              .toInt(),
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Calculated from effective scans × Rp 10.000',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // BASE SALARY
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
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
              errorBuilder: (_, _, _) => Container(
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

  void _showModalAttendance(BuildContext context, String note, String date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Attendance Note',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(date, style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                child: Text(note.isNotEmpty ? note : 'No note available'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
