import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/dealer_model.dart';
import '../models/ledger_model.dart';

class ReportService {
  final _currencyFmt = NumberFormat('#,##0.00', 'en_IN');

  String _fmt(double v) => '₹${_currencyFmt.format(v)}';

  Future<pw.Document> _buildPdf(
      DealerModel dealer, List<LedgerModel> entries) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final totalDebit = entries.fold(0.0, (s, e) => s + e.debit);
    final totalCredit = entries.fold(0.0, (s, e) => s + e.credit);
    final balance = totalDebit - totalCredit;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Text('Dealer Ledger Report',
              style: pw.TextStyle(font: fontBold, fontSize: 20)),
          pw.SizedBox(height: 8),
          pw.Text('Dealer: ${dealer.name}',
              style: pw.TextStyle(font: fontBold, fontSize: 14)),
          if (dealer.phone.isNotEmpty)
            pw.Text('Phone: ${dealer.phone}',
                style: pw.TextStyle(font: font, fontSize: 11)),
          if (dealer.address.isNotEmpty)
            pw.Text('Address: ${dealer.address}',
                style: pw.TextStyle(font: font, fontSize: 11)),
          pw.Text(
              'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 8),

          // Summary row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox('Total Debit', _fmt(totalDebit), fontBold, PdfColors.red100),
              _summaryBox('Total Credit', _fmt(totalCredit), fontBold, PdfColors.green100),
              _summaryBox('Balance Due', _fmt(balance), fontBold,
                  balance > 0 ? PdfColors.orange100 : PdfColors.green100),
            ],
          ),
          pw.SizedBox(height: 16),

          // Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FlexColumnWidth(3),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: ['Date', 'Bill No', 'Debit', 'Credit', 'Balance', 'Remarks']
                    .map((h) => _cell(h, fontBold, bold: true))
                    .toList(),
              ),
              // Data rows
              ...entries.map((e) => pw.TableRow(
                    children: [
                      _cell(e.date, font),
                      _cell(e.billNo, font),
                      _cell(e.debit > 0 ? _fmt(e.debit) : '-', font),
                      _cell(e.credit > 0 ? _fmt(e.credit) : '-', font),
                      _cell(_fmt(e.runningTotal), font),
                      _cell(e.remarks, font),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
    return doc;
  }

  pw.Widget _summaryBox(
      String label, String value, pw.Font font, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
          color: bg, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 12)),
        ],
      ),
    );
  }

  pw.Widget _cell(String text, pw.Font font, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text,
            style: pw.TextStyle(
                font: font, fontSize: bold ? 10 : 9)),
      );

  Future<File> savePdf(DealerModel dealer, List<LedgerModel> entries) async {
    final doc = await _buildPdf(dealer, entries);
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        '${dealer.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> printPdf(DealerModel dealer, List<LedgerModel> entries) async {
    final doc = await _buildPdf(dealer, entries);
    await Printing.layoutPdf(onLayout: (fmt) async => doc.save());
  }

  Future<void> sharePdf(DealerModel dealer, List<LedgerModel> entries) async {
    final doc = await _buildPdf(dealer, entries);
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          '${dealer.name}_ledger_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
