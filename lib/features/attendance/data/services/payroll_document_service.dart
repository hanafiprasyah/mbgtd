import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:mbg_test/features/attendance/data/models/payroll_period_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PayrollDocumentService {
  static final _money = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Shares a UTF-8 CSV with BOM. Excel opens it directly while preserving
  /// Indonesian characters; it is intentionally generated from snapshots only.
  static Future<void> exportReportCsv(List<PayrollPeriod> periods) async {
    final rows = <List<String>>[
      [
        'Tanggal reset',
        'Total pengeluaran',
        'Jumlah relawan',
        'Tim',
        'Total tim',
      ],
      ...periods.expand((period) {
        if (period.teamTotal.isEmpty) {
          return [
            [
              _date(period.resetAt),
              '${period.grandTotal}',
              '${period.volunteers.length}',
              '-',
              '0',
            ],
          ];
        }
        return period.teamTotal.entries.map(
          (team) => [
            _date(period.resetAt),
            '${period.grandTotal}',
            '${period.volunteers.length}',
            team.key,
            '${team.value}',
          ],
        );
      }),
    ];
    final csv =
        '\uFEFF${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}';
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(csv)),
            mimeType: 'text/csv',
            name:
                'laporan_payroll_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
          ),
        ],
        text: 'Arsip laporan payroll',
      ),
    );
  }

  static Future<void> exportSlipPdf({
    required PayrollPeriod period,
    required Map<String, dynamic> data,
  }) async {
    // Base14 fonts (Helvetica/Helvetica-Bold) only cover a narrow Latin
    // subset and print a "no Unicode support" warning for anything outside
    // it. Noto Sans covers the full range we need (Indonesian text,
    // currency formatting, punctuation) without that limitation.
    // See: https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );
    final name = (data['nama'] ?? data['namaLengkap'] ?? 'Volunteer')
        .toString();
    final team = (data['tim'] ?? '-').toString();
    final salary = _number(
      data['totalGaji'] ?? data['totalSalary'] ?? data['gaji'],
    );
    final scans = _number(data['totalScan'] ?? data['totalScans']);
    final effective = data['effectiveScan'] ?? data['effectiveScans'] ?? scans;

    // Primary color used throughout the app (adjust to match your theme)
    final primaryColor = PdfColors.blue700;

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Text(
              'VOLUNTEER PAYSLIP',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Period closed: ${_date(period.resetAt)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: primaryColor, thickness: 2),
            pw.SizedBox(height: 16),

            // Data rows
            _buildInfoRow('Name', name),
            _buildInfoRow('Team', team),
            _buildInfoRow('Recorded attendance', '$scans days'),
            _buildInfoRow('Effective attendance', '$effective days'),

            pw.SizedBox(height: 24),

            // Total box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TOTAL RECEIVED',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _money.format(salary),
                    style: const pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated on: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Document automatically generated from payroll snapshot.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await document.save();

    // New filename format: <Nama>-<TanggalExport>-SlipMBGTD-2026.pdf
    final filename =
        '${_safeName(name)}-${DateFormat('ddMMyyyy').format(DateTime.now())}-SlipMBGTD-2026.pdf';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: filename),
        ],
        text: 'Volunteer payslip',
      ),
    );
  }

  // Helper to build a label‑value row
  static pw.Widget _buildInfoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 140,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  static String _date(DateTime value) =>
      DateFormat('d MMMM y', 'en_US').format(value);
  static String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';
  static num _number(dynamic value) =>
      value is num ? value : num.tryParse('$value') ?? 0;
  static String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
