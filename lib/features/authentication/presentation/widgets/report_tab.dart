import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/features/attendance/data/models/payroll_period_model.dart';
import 'package:mbg_test/features/attendance/data/repositories/payroll_report_repository.dart';
import 'package:mbg_test/features/attendance/data/services/payroll_document_service.dart';

enum ReportRange { day, week, month, year }

Widget buildReportTab(BuildContext context) => const PayrollReportTab();

class PayrollReportTab extends StatefulWidget {
  const PayrollReportTab({super.key});
  @override
  State<PayrollReportTab> createState() => _PayrollReportTabState();
}

class _PayrollReportTabState extends State<PayrollReportTab> {
  final _repository = PayrollReportRepository();
  ReportRange _range = ReportRange.month;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month - 5, 1),
    end: DateTime.now(),
  );

  List<PayrollPeriod> _filtered(List<PayrollPeriod> all) => all
      .where(
        (p) =>
            !p.resetAt.isBefore(_dateRange.start) &&
            !p.resetAt.isAfter(_dateRange.end.add(const Duration(days: 1))),
      )
      .toList();

  void _setRange(ReportRange range) {
    final now = DateTime.now();
    final start = switch (range) {
      ReportRange.day => DateTime(now.year, now.month, now.day),
      ReportRange.week => now.subtract(Duration(days: now.weekday - 1)),
      ReportRange.month => DateTime(now.year, now.month, 1),
      ReportRange.year => DateTime(now.year, 1, 1),
    };
    setState(() {
      _range = range;
      _dateRange = DateTimeRange(start: start, end: now);
    });
  }

  Future<void> _pickDates() async {
    final chosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (chosen != null) {
      setState(() => _dateRange = chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Payroll Report'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.surfaceContainerLowest,
        elevation: 0,
      ),
      body: StreamBuilder<List<PayrollPeriod>>(
        stream: _repository.watchPayrollPeriods(),
        builder: (context, snapshot) {
          Widget child;
          if (snapshot.hasError) {
            child = _StateMessage(
              key: const ValueKey('error'),
              icon: Icons.cloud_off_rounded,
              message: 'The report could not be loaded.',
              detail: 'Please check your Firebase access and try again.',
            );
          } else if (!snapshot.hasData) {
            child = const Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator(),
            );
          } else {
            final periods = _filtered(snapshot.data!);
            child = RefreshIndicator(
              key: const ValueKey('content'),
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    'Analysis based on closed period snapshots.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  _FilterBar(
                    range: _range,
                    dates: _dateRange,
                    onRange: _setRange,
                    onCustom: _pickDates,
                  ),
                  const SizedBox(height: 24),
                  if (periods.isEmpty)
                    _StateMessage(
                      icon: Icons.receipt_long_outlined,
                      message: 'No data yet',
                      detail: 'No payroll snapshots in this range yet.',
                    )
                  else ...[
                    _SummaryCards(periods: periods),
                    const SizedBox(height: 16),
                    _MonthlySpendChart(periods: periods),
                    const SizedBox(height: 16),
                    _TeamSpendCard(periods: periods),
                    const SizedBox(height: 16),
                    _ExportCard(periods: periods),
                  ],
                ],
              ),
            );
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: child,
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.range,
    required this.dates,
    required this.onRange,
    required this.onCustom,
  });
  final ReportRange range;
  final DateTimeRange dates;
  final ValueChanged<ReportRange> onRange;
  final VoidCallback onCustom;

  static const _labels = {
    ReportRange.day: 'Daily',
    ReportRange.week: 'Weekly',
    ReportRange.month: 'Monthly',
    ReportRange.year: 'Yearly',
  };

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReportRange.values
              .map(
                (item) => ChoiceChip(
                  label: Text(_labels[item]!),
                  selected: range == item,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: range == item ? c.onPrimary : c.onSurfaceVariant,
                  ),
                  selectedColor: c.primary,
                  backgroundColor: c.surfaceContainerHigh,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (_) => onRange(item),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCustom,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(color: c.outlineVariant),
              alignment: Alignment.centerLeft,
            ),
            icon: Icon(Icons.date_range_outlined, size: 18, color: c.primary),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${DateFormat('d MMM y', 'en_US').format(dates.start)}  –  ${DateFormat('d MMM y', 'en_US').format(dates.end)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.periods});
  final List<PayrollPeriod> periods;
  @override
  Widget build(BuildContext context) {
    final total = periods.fold<int>(0, (v, p) => v + p.grandTotal);
    final volunteers = periods.fold<int>(0, (v, p) => v + p.volunteers.length);
    final money = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _Metric(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Total spending',
            value: money.format(total),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: _Metric(
            icon: Icons.groups_rounded,
            label: 'Slips issued',
            value: '$volunteers',
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: c.primary, size: 20),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MonthlySpendChart extends StatelessWidget {
  const _MonthlySpendChart({required this.periods});
  final List<PayrollPeriod> periods;
  @override
  Widget build(BuildContext context) {
    final amounts = <String, int>{};
    for (final p in periods) {
      final key = DateFormat('MMM', 'en_US').format(p.resetAt);
      amounts[key] = (amounts[key] ?? 0) + p.grandTotal;
    }
    return _Panel(
      title: 'Total monthly spending',
      child: Column(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _SpendChartPainter(
                amounts.values.toList(),
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amounts.entries
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${e.key} · ${NumberFormat.compactCurrency(locale: 'en_US', symbol: 'Rp ').format(e.value)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SpendChartPainter extends CustomPainter {
  _SpendChartPainter(this.values, this.color);
  final List<int> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: .18), color.withValues(alpha: .0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final max = values.reduce((a, b) => a > b ? a : b).toDouble();
    final safeMax = max == 0 ? 1 : max;
    final path = Path();
    final area = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i * size.width / (values.length - 1);
      final y = size.height - 14 - (values[i] / safeMax) * (size.height - 34);
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }
    area.lineTo(size.width, size.height);
    area.close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, paint);
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i * size.width / (values.length - 1);
      final y = size.height - 14 - (values[i] / safeMax) * (size.height - 34);
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SpendChartPainter old) =>
      old.values != values || old.color != color;
}

class _TeamSpendCard extends StatelessWidget {
  const _TeamSpendCard({required this.periods});
  final List<PayrollPeriod> periods;
  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    for (final p in periods) {
      p.teamTotal.forEach((k, v) => totals[k] = (totals[k] ?? 0) + v);
    }
    final max = totals.values.isEmpty
        ? 1
        : totals.values.reduce((a, b) => a > b ? a : b);
    final c = Theme.of(context).colorScheme;
    return _Panel(
      title: 'Spending breakdown by team',
      child: Column(
        children: totals.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              NumberFormat.compactCurrency(
                                locale: 'en_US',
                                symbol: 'Rp ',
                              ).format(e.value),
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: e.value / max,
                        backgroundColor: c.surfaceContainerHigh,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.periods});
  final List<PayrollPeriod> periods;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => PayrollDocumentService.exportReportCsv(periods),
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Export to Excel (.csv)'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'CSV is compatible with Microsoft Excel for kitchen archives.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    super.key,
    required this.icon,
    required this.message,
    this.detail,
  });
  final IconData icon;
  final String message;
  final String? detail;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: c.outline),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
