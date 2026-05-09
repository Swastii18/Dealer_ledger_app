import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ledger_controller.dart';
import '../models/dealer_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/ledger_tile.dart';

class DealerLedgerScreen extends StatefulWidget {
  const DealerLedgerScreen({super.key});

  @override
  State<DealerLedgerScreen> createState() => _DealerLedgerScreenState();
}

class _DealerLedgerScreenState extends State<DealerLedgerScreen> {
  late final LedgerController _ctrl;
  late final DealerModel _dealer;

  @override
  void initState() {
    super.initState();
    _dealer = Get.arguments as DealerModel;
    _ctrl = Get.find<LedgerController>();
    _ctrl.searchQuery.value = '';
    _ctrl.filterDate.value = '';
    _ctrl.loadLedger(_dealer.id!);
  }

  void _confirmDelete(int entryId) {
    Get.defaultDialog(
      title: 'Delete Entry',
      middleText: 'Remove this ledger entry?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        _ctrl.deleteLedgerEntry(entryId);
      },
    );
  }

  String _fmt(double v) => '₹${NumberFormat('#,##0.00', 'en_IN').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dealer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: () =>
                Get.toNamed(AppRoutes.reports, arguments: _dealer),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => _ctrl.searchQuery.value = v,
              decoration: const InputDecoration(
                hintText: 'Search bill no, date, remarks...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Balance header
          Obx(() => Container(
                color: AppTheme.primary.withValues(alpha: 0.05),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _balancePill('Debit', _fmt(_ctrl.totalDebit),
                        AppTheme.debitColor),
                    _balancePill('Credit', _fmt(_ctrl.totalCredit),
                        AppTheme.creditColor),
                    _balancePill(
                        'Balance',
                        _fmt(_ctrl.currentBalance),
                        _ctrl.currentBalance > 0
                            ? AppTheme.debitColor
                            : AppTheme.creditColor),
                  ],
                ),
              )),
          // Ledger list
          Expanded(
            child: Obx(() {
              if (_ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = _ctrl.filteredEntries;
              if (entries.isEmpty) {
                return const Center(
                  child: Text('No entries yet.\nScan a bill or add a payment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: entries.length,
                itemBuilder: (_, i) => LedgerTile(
                  entry: entries[i],
                  onDelete: () => _confirmDelete(entries[i].id!),
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Get.toNamed(AppRoutes.scanBill, arguments: _dealer),
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Scan Bill'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.creditColor),
                  onPressed: () =>
                      Get.toNamed(AppRoutes.addPayment, arguments: _dealer),
                  icon: const Icon(Icons.payments),
                  label: const Text('Add Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balancePill(String label, String value, Color color) => Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      );
}
