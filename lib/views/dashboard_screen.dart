import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dealer_controller.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final DealerController _ctrl = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() => _ctrl.loadDealers();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'All Dealers',
            onPressed: () async {
              await Get.toNamed(AppRoutes.dealerList);
              _refresh(); // refresh totals when returning
            },
          ),
        ],
      ),
      body: Obx(() {
        final dealers = _ctrl.dealers;
        final balances = _ctrl.balances;
        final totalDebit =
            balances.values.where((b) => b > 0).fold(0.0, (s, b) => s + b);
        final totalCredit =
            balances.values.where((b) => b < 0).fold(0.0, (s, b) => s + b.abs());
        final netBalance = balances.values.fold(0.0, (s, b) => s + b);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _sectionLabel('Overview'),
              const SizedBox(height: 8),
              SummaryCard(
                label: 'Total Dealers',
                value: '${dealers.length}',
                icon: Icons.store,
                color: AppTheme.primary,
              ),
              SummaryCard(
                label: 'Total Due (Debit)',
                value: fmtAmount(totalDebit),
                icon: Icons.trending_up,
                color: AppTheme.debitColor,
              ),
              SummaryCard(
                label: 'Total Paid (Credit)',
                value: fmtAmount(totalCredit),
                icon: Icons.trending_down,
                color: AppTheme.creditColor,
              ),
              SummaryCard(
                label: 'Net Balance',
                value: fmtAmount(netBalance),
                icon: Icons.account_balance_wallet,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 20),
              _sectionLabel('Recent Dealers'),
              const SizedBox(height: 8),
              if (dealers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No dealers yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...dealers.take(5).map((d) {
                  final balance = balances[d.id] ?? 0;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          d.name[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(d.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          d.phone.isNotEmpty ? d.phone : 'No phone'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmtAmount(balance.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: balance > 0
                                  ? AppTheme.debitColor
                                  : AppTheme.creditColor,
                            ),
                          ),
                          Text(
                            balance > 0 ? 'Due' : 'Settled',
                            style: TextStyle(
                              fontSize: 11,
                              color: balance > 0
                                  ? AppTheme.debitColor
                                  : AppTheme.creditColor,
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await Get.toNamed(AppRoutes.dealerLedger,
                            arguments: d);
                        _refresh();
                      },
                    ),
                  );
                }),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.toNamed(AppRoutes.dealerList);
          _refresh();
        },
        icon: const Icon(Icons.people_alt),
        label: const Text('View Dealers'),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.8,
          ),
        ),
      );
}
