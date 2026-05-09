import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dealer_controller.dart';
import '../models/dealer_model.dart';
import '../routes/app_routes.dart';
import '../widgets/dealer_card.dart';

class DealerListScreen extends StatefulWidget {
  const DealerListScreen({super.key});

  @override
  State<DealerListScreen> createState() => _DealerListScreenState();
}

class _DealerListScreenState extends State<DealerListScreen> {
  final DealerController _ctrl = Get.find();
  final Map<int, double> _balances = {};

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    for (final d in _ctrl.dealers) {
      if (d.id != null) {
        _balances[d.id!] = await _ctrl.getDealerBalance(d.id!);
      }
    }
    if (mounted) setState(() {});
  }

  void _confirmDelete(DealerModel dealer) {
    Get.defaultDialog(
      title: 'Delete Dealer',
      middleText:
          'Delete ${dealer.name} and all their records? This cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        _ctrl.deleteDealer(dealer.id!, dealer.name);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => _ctrl.searchQuery.value = v,
              decoration: const InputDecoration(
                hintText: 'Search dealers...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = _ctrl.filteredDealers;
        if (list.isEmpty) {
          return const Center(
            child: Text('No dealers found.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await _ctrl.loadDealers();
            await _loadBalances();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final dealer = list[i];
              return DealerCard(
                dealer: dealer,
                balance: _balances[dealer.id] ?? 0,
                onTap: () =>
                    Get.toNamed(AppRoutes.dealerLedger, arguments: dealer),
                onEdit: () =>
                    Get.toNamed(AppRoutes.addDealer, arguments: dealer),
                onDelete: () => _confirmDelete(dealer),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Get.toNamed(AppRoutes.addDealer);
          await _loadBalances();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
