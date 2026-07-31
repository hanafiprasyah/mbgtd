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
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.surfaceContainerLowest,
      ),
      body: StreamBuilder<List<PayrollPeriod>>(
        stream: _repository.watchPayrollPeriods(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.cloud_off_rounded,
              message:
                  'The report could not be loaded. Please check your Firebase access.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final periods = _filtered(snapshot.data!);
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  'Payroll cost control',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analysis based on closed period snapshots.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                _FilterBar(
                  range: _range,
                  dates: _dateRange,
                  onRange: _setRange,
                  onCustom: _pickDates,
                ),
                const SizedBox(height: 20),
                if (periods.isEmpty)
                  const _StateMessage(
                    icon: Icons.receipt_long_outlined,
                    message: 'No payroll snapshots in this range yet.',
                  )
                else ...[
                  _SummaryCards(periods: periods),
                  const SizedBox(height: 20),
                  _MonthlySpendChart(periods: periods),
                  const SizedBox(height: 20),
                  _TeamSpendCard(periods: periods),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () =>
                        PayrollDocumentService.exportReportCsv(periods),
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('Export to Excel (.csv)'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CSV is compatible with Microsoft Excel for kitchen archives.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
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
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ReportRange.values
            .map(
              (item) => ChoiceChip(
                label: Text(switch (item) {
                  ReportRange.day => 'Daily',
                  ReportRange.week => 'Weekly',
                  ReportRange.month => 'Monthly',
                  ReportRange.year => 'Yearly',
                }),
                selected: range == item,
                onSelected: (_) => onRange(item),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: onCustom,
        icon: const Icon(Icons.date_range_outlined, size: 18),
        label: Text(
          '${DateFormat('d MMM y', 'en_US').format(dates.start)} – ${DateFormat('d MMM y', 'en_US').format(dates.end)}',
        ),
      ),
    ],
  );
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
      children: [
        Expanded(
          child: _Metric(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Total spending',
            value: money.format(total),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
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
        color: c.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.primary),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(
              color: c.onPrimaryContainer.withValues(alpha: .75),
              fontSize: 12,
            ),
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
            height: 180,
            child: CustomPaint(
              painter: _SpendChartPainter(
                amounts.values.toList(),
                Theme.of(context).colorScheme.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: amounts.entries
                .map(
                  (e) => Text(
                    '${e.key}: ${NumberFormat.compactCurrency(locale: 'en_US', symbol: 'Rp ').format(e.value)}',
                    style: const TextStyle(fontSize: 11),
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
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.fill;
    final max = values.reduce((a, b) => a > b ? a : b).toDouble();
    final path = Path();
    final area = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i * size.width / (values.length - 1);
      final y = size.height - 12 - (values[i] / max) * (size.height - 30);
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
      final y = size.height - 12 - (values[i] / max) * (size.height - 30);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
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
    return _Panel(
      title: 'Spending breakdown by team',
      child: Column(
        children: totals.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.key)),
                        Text(
                          NumberFormat.compactCurrency(
                            locale: 'en_US',
                            symbol: 'Rp ',
                          ).format(e.value),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: e.value / max,
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 8,
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

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
  const _StateMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(icon, size: 42, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
