import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/dealer_controller.dart';
import '../routes/app_routes.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DealerController _dealerCtrl = Get.find();
  final DatabaseService _db = DatabaseService();
  double _totalDebit = 0;
  double _totalCredit = 0;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  Future<void> _loadTotals() async {
    final totals = await _db.getDashboardTotals();
    if (mounted) {
      setState(() {
        _totalDebit = totals['totalDebit'] ?? 0;
        _totalCredit = totals['totalCredit'] ?? 0;
      });
    }
  }

  String _fmt(double v) => '₹${NumberFormat('#,##0.00', 'en_IN').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'All Dealers',
            onPressed: () => Get.toNamed(AppRoutes.dealerList),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _dealerCtrl.loadDealers();
          await _loadTotals();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Overview',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.8)),
            ),
            const SizedBox(height: 8),
            Obx(() => SummaryCard(
                  label: 'Total Dealers',
                  value: '${_dealerCtrl.dealers.length}',
                  icon: Icons.store,
                  color: AppTheme.primary,
                )),
            SummaryCard(
              label: 'Total Due (Debit)',
              value: _fmt(_totalDebit),
              icon: Icons.trending_up,
              color: AppTheme.debitColor,
            ),
            SummaryCard(
              label: 'Total Paid (Credit)',
              value: _fmt(_totalCredit),
              icon: Icons.trending_down,
              color: AppTheme.creditColor,
            ),
            SummaryCard(
              label: 'Net Balance',
              value: _fmt(_totalDebit - _totalCredit),
              icon: Icons.account_balance_wallet,
              color: AppTheme.accent,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Recent Dealers',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.8)),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final list = _dealerCtrl.dealers.take(5).toList();
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No dealers yet.\nTap + to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return Column(
                children: list
                    .map((d) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.1),
                              child: Text(d.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(d.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(d.phone.isNotEmpty ? d.phone : 'No phone'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Get.toNamed(AppRoutes.dealerLedger,
                                arguments: d),
                          ),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.dealerList),
        icon: const Icon(Icons.people_alt),
        label: const Text('View Dealers'),
      ),
    );
  }
}
