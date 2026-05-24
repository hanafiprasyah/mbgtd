import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/core/helper/salary_calculator.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_payroll_repository.dart';
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
        SnackBar(content: Text('Reset gagal: $e'), backgroundColor: Colors.red),
      );
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
    return Scaffold(
      appBar: AppBar(
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
                ...salaryPerTim.keys.map(
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
              stream: AttendancePayrollRepository()
                  .getPayrollStream()
                  .debounceTime(const Duration(milliseconds: 300)),
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
                      'Terjadi error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No payroll data'));
                }

                final rawData = snapshot.data!;

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
                                  '$team (Total: ${currencyFormatter.format(totalTeam)})',
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
                                              const SizedBox(height: 4),
                                              Text(
                                                '${(item['totalScan'] ?? 0) > 0 ? '${item['totalScan']} days' : 'No scan'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
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
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
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
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                            ),
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
                    }).toList(),
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
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
