import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ledger_controller.dart';
import '../models/dealer_model.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final LedgerController _ctrl = Get.find();
  final ReportService _reportService = ReportService();
  late final DealerModel _dealer;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _dealer = Get.arguments as DealerModel;
    if (_ctrl.entries.isEmpty) _ctrl.loadLedger(_dealer.id!);
  }

  String _fmt(double v) => '₹${NumberFormat('#,##0.00', 'en_IN').format(v)}';

  Future<void> _sharePdf() async {
    setState(() => _exporting = true);
    try {
      await _reportService.sharePdf(_dealer, _ctrl.entries);
    } catch (e) {
      Get.snackbar('Error', 'Could not generate PDF: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<void> _printPdf() async {
    setState(() => _exporting = true);
    try {
      await _reportService.printPdf(_dealer, _ctrl.entries);
    } catch (e) {
      Get.snackbar('Error', 'Could not print PDF: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_dealer.name} – Report')),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = _ctrl.entries;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Dealer info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dealer.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    if (_dealer.phone.isNotEmpty)
                      Text(_dealer.phone,
                          style: TextStyle(color: Colors.grey[600])),
                    if (_dealer.address.isNotEmpty)
                      Text(_dealer.address,
                          style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _summaryRow('Total Transactions', '${entries.length}',
                        Colors.blueGrey),
                    const Divider(),
                    _summaryRow('Total Debit', _fmt(_ctrl.totalDebit),
                        AppTheme.debitColor),
                    _summaryRow('Total Credit', _fmt(_ctrl.totalCredit),
                        AppTheme.creditColor),
                    const Divider(),
                    _summaryRow('Net Balance Due', _fmt(_ctrl.currentBalance),
                        _ctrl.currentBalance > 0
                            ? AppTheme.debitColor
                            : AppTheme.creditColor,
                        bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isNotEmpty) ...[
              Text('Transaction History',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontSize: 13)),
              const SizedBox(height: 8),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        AppTheme.primary.withValues(alpha: 0.07)),
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Bill No')),
                      DataColumn(label: Text('Debit'), numeric: true),
                      DataColumn(label: Text('Credit'), numeric: true),
                      DataColumn(label: Text('Balance'), numeric: true),
                    ],
                    rows: entries
                        .map((e) => DataRow(cells: [
                              DataCell(Text(e.date,
                                  style: const TextStyle(fontSize: 12))),
                              DataCell(Text(e.billNo,
                                  style: const TextStyle(fontSize: 12))),
                              DataCell(Text(
                                  e.debit > 0
                                      ? _fmt(e.debit)
                                      : '-',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: e.debit > 0
                                          ? AppTheme.debitColor
                                          : null))),
                              DataCell(Text(
                                  e.credit > 0
                                      ? _fmt(e.credit)
                                      : '-',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: e.credit > 0
                                          ? AppTheme.creditColor
                                          : null))),
                              DataCell(Text(_fmt(e.runningTotal),
                                  style: const TextStyle(fontSize: 12))),
                            ]))
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Export buttons
            ElevatedButton.icon(
              onPressed: _exporting ? null : _sharePdf,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.share),
              label: const Text('Share as PDF'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _exporting ? null : _printPdf,
              icon: const Icon(Icons.print),
              label: const Text('Print PDF'),
            ),
          ],
        );
      }),
    );
  }

  Widget _summaryRow(String label, String value, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
