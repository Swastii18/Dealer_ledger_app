import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ledger_controller.dart';
import '../models/dealer_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ledger_tile.dart';

class DealerLedgerScreen extends StatefulWidget {
  const DealerLedgerScreen({super.key});

  @override
  State<DealerLedgerScreen> createState() => _DealerLedgerScreenState();
}

class _DealerLedgerScreenState extends State<DealerLedgerScreen> {
  late final LedgerController _ctrl;
  late final DealerModel _dealer;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dealer = Get.arguments as DealerModel;
    _ctrl = Get.find<LedgerController>();
    // Clear previous dealer's search/filter state
    _ctrl.searchQuery.value = '';
    _ctrl.filterDate.value = '';
    _searchCtrl.clear();
    _ctrl.loadLedger(_dealer.id!);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext ctx, int entryId) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Remove this ledger entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) _ctrl.deleteLedgerEntry(entryId);
  }

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
              controller: _searchCtrl,
              onChanged: (v) => _ctrl.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Search bill no, date, remarks...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                suffixIcon: Obx(() => _ctrl.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _ctrl.searchQuery.value = '';
                        },
                      )
                    : const SizedBox.shrink()),
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
                    _balancePill('Debit', fmtAmount(_ctrl.totalDebit),
                        AppTheme.debitColor),
                    _balancePill('Credit', fmtAmount(_ctrl.totalCredit),
                        AppTheme.creditColor),
                    _balancePill(
                        'Balance',
                        fmtAmount(_ctrl.currentBalance),
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
                final isEmpty = _ctrl.entries.isEmpty;
                return Center(
                  child: Text(
                    isEmpty
                        ? 'No entries yet.\nScan a bill or add a payment.'
                        : 'No results for "${_ctrl.searchQuery.value}".',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: entries.length,
                itemBuilder: (ctx, i) => LedgerTile(
                  key: ValueKey(entries[i].id),
                  entry: entries[i],
                  onDelete: () => _confirmDelete(ctx, entries[i].id!),
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
