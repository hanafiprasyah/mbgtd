import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/core/helper/salary_calculator.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_payroll_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/attendance/presentation/pages/attendance_edit.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:rxdart/rxdart.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage>
    with SingleTickerProviderStateMixin {
  String selectedTim = 'all';
  String? lastHighlightedId;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  String _formatEffectiveAttendance(dynamic value) {
    final effectiveAttendance = value is num ? value.toDouble() : 0.0;
    final formatted = effectiveAttendance.toStringAsFixed(2);

    return formatted.endsWith('.00')
        ? effectiveAttendance.toStringAsFixed(0)
        : formatted;
  }

  // set PIC function with Bloc event
  void _handleSetPIC(BuildContext context, Map<String, dynamic> item) async {
    // Confirmation dialog before any logic
    final volunteer = item;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm PIC Assignment',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to assign ${volunteer['nama']} as the PIC of ${volunteer['tim']} team?\n\n'
            'The current PIC will lose their payroll bonus, and it will be reassigned to ${volunteer['nama']}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Assign'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final volunteerId = item['id'];
    final isPIC = item['isPIC'] ?? false;
    final tim = item['tim'];
    if (volunteerId == null) return;

    context.read<VolunteerBloc>().add(
      ToggleVolunteerPIC(volunteerId, isPIC, tim),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PIC status updated')));
  }

  void _showScanHistory(BuildContext context, Map<String, dynamic> item) {
    final volunteerId = item['id'];
    final volunteerName = item['nama'] ?? '-';

    if (volunteerId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // HANDLE BAR
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TITLE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.history,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            volunteerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // LIST
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('attendances')
                          .where('volunteerId', isEqualTo: volunteerId)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        // 🔴 HANDLE ERROR
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error while fetching history. Please try again.',
                            ),
                          );
                        }

                        // ⏳ LOADING STATE
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        // 🚨 DATA NULL GUARD
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('No data available'));
                        }

                        final docs = snapshot.data!.docs;

                        // 📭 EMPTY STATE
                        if (docs.isEmpty) {
                          return Center(child: Text('No scan history'));
                        }

                        // ✅ DATA exist
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;

                            String docID = docs[index].id;
                            data['id'] = docID; // add document ID to data map

                            final ts = data['timestamp'];
                            DateTime? dateTime;
                            if (ts is Timestamp) {
                              dateTime = ts.toDate();
                            }

                            final formattedDate = dateTime != null
                                ? DateFormat(
                                    'dd MMM yyyy • HH:mm',
                                  ).format(dateTime)
                                : (data['date'] ?? '-');

                            final isLatest = index == 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // TIMELINE
                                  Column(
                                    children: [
                                      Container(
                                        width: 2,
                                        height: 12,
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isLatest
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey.withValues(
                                                  alpha: 0.4,
                                                ),
                                        ),
                                      ),
                                      Container(
                                        width: 2,
                                        height: 60,
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 10),

                                  // CARD CONTENT
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: Theme.of(context).cardColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: isLatest
                                                ? Theme.of(context).primaryColor
                                                      .withValues(alpha: 0.5)
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                            blurRadius: isLatest ? 16 : 8,
                                            spreadRadius: isLatest ? 2 : 0,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        border: isLatest
                                            ? Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.qr_code_scanner,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Scanned by ${data['scannedByEmail'] ?? '-'}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            // Safer attendanceType handling
                                            (() {
                                              final attendanceType =
                                                  data['attendanceType'];
                                              final multiplier =
                                                  (data['multiplier'] is num)
                                                  ? (data['multiplier'] as num)
                                                        .toDouble()
                                                  : null;
                                              final isAbsent =
                                                  attendanceType == 'absent' ||
                                                  multiplier == 0;
                                              final isHalfDay =
                                                  !isAbsent &&
                                                  attendanceType != null &&
                                                  attendanceType != 'full';
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: attendanceType == null
                                                      ? Colors.grey.withValues(
                                                          alpha: 0.15,
                                                        )
                                                      : isAbsent
                                                      ? Colors.red.withValues(
                                                          alpha: 0.15,
                                                        )
                                                      : isHalfDay
                                                      ? Colors.amber.withValues(
                                                          alpha: 0.15,
                                                        )
                                                      : Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  attendanceType == null
                                                      ? 'Not Set'
                                                      : isAbsent
                                                      ? 'Absent'
                                                      : isHalfDay
                                                      ? 'Half Day'
                                                      : 'Full Day',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        attendanceType == null
                                                        ? Colors.grey
                                                        : isAbsent
                                                        ? Colors.red.shade700
                                                        : isHalfDay
                                                        ? Colors.amber.shade800
                                                        : Theme.of(
                                                            context,
                                                          ).primaryColor,
                                                  ),
                                                ),
                                              );
                                            })(),
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isLatest
                                                      ? Colors.amber.withValues(
                                                          alpha: 0.15,
                                                        )
                                                      : Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  isLatest ? 'Latest' : 'Past',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w600,
                                                    color: isLatest
                                                        ? Colors.amber.shade800
                                                        : Theme.of(
                                                            context,
                                                          ).primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EditAttendancePage(
                                                      attendanceId:
                                                          data['id'] ?? '',
                                                      data: data,
                                                    ),
                                              ),
                                            );
                                            // Navigator.pushNamed(
                                            //   context,
                                            //   '/edit-attendance',
                                            //   arguments: {
                                            //     'attendanceId': data['id'],
                                            //     'data': data,
                                            //   },
                                            // );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _resetPeriod() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    try {
      final attendanceSnap = await firestore.collection('attendances').get();
      final batch = firestore.batch();

      for (var doc in attendanceSnap.docs) {
        batch.delete(doc.reference);
      }

      final periodRef = firestore.collection('attendance_periods').doc();

      batch.set(periodRef, {
        'resetAt': now,
        'totalDeleted': attendanceSnap.docs.length,
      });

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance reset for new period')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDisplayDate(String dateStr) {
    if (dateStr.isEmpty || dateStr == '-') return dateStr;
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('d MMM yyyy', 'en_US').format(parsed);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surfaceContainerLowest,
        title: const Text('Payroll Volunteer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Period',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Period'),
                  content: const Text(
                    'Are you sure you want to reset attendance for a new period?',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _resetPeriod();
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => Navigator.pushNamed(context, '/payroll-history'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: selectedTim,
              decoration: const InputDecoration(
                labelText: 'Filter by Team',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All')),
                ...payrollRules.keys.map(
                  (tim) => DropdownMenuItem(
                    value: tim,
                    child: Text(tim.toString().trim()),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedTim = value!;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: Rx.combineLatest2(
                AttendancePayrollRepository().getPayrollStream(),
                AttendancePayrollRepository().getTeamDaySummaryStream(),
                (
                  Map<String, dynamic> volunteersMap,
                  Map<String, Map<String, dynamic>> teamDaySummary,
                ) {
                  return {
                    'volunteers': volunteersMap,
                    'teamDaySummary': teamDaySummary,
                  };
                },
              ).debounceTime(const Duration(milliseconds: 300)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          'Loading payroll data...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error encountered: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No payroll data'));
                }

                final combined = snapshot.data!;
                final rawData = combined.containsKey('volunteers')
                    ? (combined['volunteers'] as Map<String, dynamic>)
                    : combined;
                final Map<String, Map<String, dynamic>> teamDaySummary =
                    combined.containsKey('teamDaySummary')
                    ? Map<String, Map<String, dynamic>>.from(
                        combined['teamDaySummary'] as Map,
                      )
                    : {};

                // Safe latest scan detection
                DateTime latestTime = DateTime.fromMillisecondsSinceEpoch(0);
                lastHighlightedId = null;

                for (var entry in rawData.entries) {
                  final data = entry.value;
                  try {
                    if (data['lastScanAt'] != null) {
                      final ts = data['lastScanAt'];
                      if (ts is Timestamp) {
                        final time = ts.toDate();
                        if (time.isAfter(latestTime)) {
                          latestTime = time;
                          lastHighlightedId = entry.key;
                        }
                      }
                    }
                  } catch (_) {
                    // silently ignore bad data to avoid crash in production
                  }
                }

                // Summary calculation
                int totalVolunteer = rawData.length;
                int totalGajiAll = 0;

                for (var e in rawData.values) {
                  totalGajiAll += (e['totalGaji'] ?? 0) as int;
                }

                // Group by team
                final Map<String, List<Map<String, dynamic>>> groupedData = {};
                final Map<String, int> teamTotals = {};

                final filteredEntries = selectedTim == 'all'
                    ? rawData.entries
                    : rawData.entries.where(
                        (e) => e.value['tim'].toString() == selectedTim,
                      );

                for (var entry in filteredEntries) {
                  final item = entry.value;
                  final tim = item['tim'] ?? 'Unknown';

                  if (!groupedData.containsKey(tim)) {
                    groupedData[tim] = [];
                    teamTotals[tim] = 0;
                  }

                  groupedData[tim]!.add(item);
                  teamTotals[tim] =
                      (teamTotals[tim] ?? 0) + (item['totalGaji'] ?? 0) as int;
                }

                if (groupedData.isEmpty) {
                  return const Center(child: Text('No payroll data'));
                }

                final teams = groupedData.keys.toList();

                // Prepare per-team per-day summaries mapping: team -> List<summary>
                final Map<String, List<Map<String, dynamic>>> teamDayMap = {};
                teamDaySummary.forEach((key, summary) {
                  final tim = summary['tim'] ?? 'Unknown';
                  teamDayMap.putIfAbsent(tim, () => []).add(summary);
                });

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // SUMMARY DASHBOARD
                    SliverToBoxAdapter(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 20, end: 0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, value),
                            child: Opacity(
                              opacity: (1 - (value / 20)).clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.9),
                                    Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Payroll Summary',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildSummaryItem(
                                            context,
                                            icon: Icons.people,
                                            label: 'Volunteer',
                                            value:
                                                '${totalVolunteer.toString()} people',
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildSummaryItem(
                                            context,
                                            icon: Icons.payments,
                                            label: 'Payroll Total',
                                            value: currencyFormatter.format(
                                              totalGajiAll,
                                            ),
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
                      ),
                    ),

                    ...teams.map((team) {
                      final items = groupedData[team]!;
                      final totalTeam = teamTotals[team] ?? 0;

                      return SliverMainAxisGroup(
                        slivers: [
                          // STICKY HEADER
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _TeamHeaderDelegate(
                              title:
                                  '$team (Total: ${currencyFormatter.format(totalTeam)}) - ${items.length} orang',
                            ),
                          ),

                          // TEAM-DAY SUMMARY (chips)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: SizedBox(
                                height: 100,
                                child: Stack(
                                  children: [
                                    ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      itemCount:
                                          (teamDayMap[team] ?? []).length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 8),
                                      physics: const BouncingScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final summary =
                                            (teamDayMap[team] ?? [])[index];

                                        final date = summary['date'] ?? '-';
                                        final displayDate = _formatDisplayDate(
                                          date,
                                        );
                                        final full = summary['fullCount'] ?? 0;
                                        final half = summary['halfCount'] ?? 0;
                                        final absent =
                                            summary['absentCount'] ?? 0;
                                        final share =
                                            summary['sharePerFull'] ?? 0.0;

                                        final today = DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(DateTime.now());
                                        final isToday = date == today;

                                        return Container(
                                          width: 140,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? Theme.of(context).primaryColor
                                                      .withValues(alpha: 0.15)
                                                : Theme.of(context).primaryColor
                                                      .withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isToday
                                                  ? Theme.of(
                                                      context,
                                                    ).primaryColor
                                                  : Theme.of(
                                                      context,
                                                    ).primaryColor.withValues(
                                                      alpha: 0.12,
                                                    ),
                                              width: isToday ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                displayDate,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                ),
                                              ),
                                              if (isToday)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'Today',
                                                    style: TextStyle(
                                                      fontSize: 6,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'F:$full • H:$half • A:$absent',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Share: ${currencyFormatter.format((share).toInt())}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // TEAM LIST
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = items[index];
                              final isHighlighted =
                                  item['id'] == lastHighlightedId;

                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 30, end: 0),
                                  duration: Duration(
                                    milliseconds: 400 + (index * 50),
                                  ),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, value),
                                      child: child,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isHighlighted
                                          ? [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 16,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Card(
                                      elevation: isHighlighted ? 6 : 3,
                                      shadowColor: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).cardColor,
                                              Theme.of(context).cardColor
                                                  .withValues(alpha: 0.95),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: ListTile(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/payroll-detail-page',
                                              arguments: item['id'],
                                            );
                                          },
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                          leading: CircleAvatar(
                                            backgroundColor: Theme.of(context)
                                                .primaryColor
                                                .withValues(
                                                  alpha: isHighlighted
                                                      ? 0.25
                                                      : 0.1,
                                                ),
                                            child: Text(
                                              (item['nama'] ?? '?')[0],
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['nama'] ?? '-',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              if ((item['isPIC'] ?? false) ==
                                                  true)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),

                                                  child: const Text(
                                                    'PIC',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                              // SALARY (moved here for better layout)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withValues(
                                                        alpha: isHighlighted
                                                            ? 0.2
                                                            : 0.1,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  currencyFormatter.format(
                                                    item['totalGaji'] ?? 0,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 2,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  Text(
                                                    (item['totalScan'] ?? 0) > 0
                                                        ? '${item['totalScan']} scan'
                                                        : 'No scan',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    '/ ${_formatEffectiveAttendance(item['effectiveScan'])} day(s)',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.teal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.qr_code_scanner,
                                                    size: 12,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      item['scannedByEmail'] ??
                                                          '-',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'set_pic') {
                                                _handleSetPIC(context, item);
                                              } else if (value == 'history') {
                                                _showScanHistory(context, item);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'history',
                                                child: Text(
                                                  'View Scan History',
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'set_pic',
                                                child: Text(
                                                  item['isPIC'] == true
                                                      ? 'Remove PIC'
                                                      : 'Set as PIC',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }, childCount: items.length),
                          ),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _TeamHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;

  _TeamHeaderDelegate({required this.title});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      alignment: Alignment.centerLeft,
      child: Builder(
        builder: (context) {
          final parts = title.split(' - ');
          final mainText = parts[0];
          final countText = parts.length > 1 ? parts[1] : '';

          return Row(
            children: [
              Expanded(
                child: Text(
                  mainText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (countText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        countText.replaceAll('orang', 'people'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 40;

  @override
  double get minExtent => 40;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

Widget _buildSummaryItem(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ],
  );
}
