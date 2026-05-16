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
  late final DealerController _ctrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<DealerController>();
    // Clear any leftover search from a previous visit
    _ctrl.searchQuery.value = '';
    _searchCtrl.clear();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(DealerModel dealer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delete Dealer'),
        content: Text(
            'Delete ${dealer.name} and all their records? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _ctrl.deleteDealer(dealer.id!, dealer.name);
    }
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
            child: Obx(() => TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => _ctrl.searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: 'Search dealers...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    suffixIcon: _ctrl.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _ctrl.searchQuery.value = '';
                            },
                          )
                        : null,
                  ),
                )),
          ),
        ),
      ),
      body: Obx(() {
        final isDeleting = _ctrl.isDeleting.value;
        final isLoading = _ctrl.isLoading.value;
        final list = _ctrl.filteredDealers;

        return Stack(
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (list.isEmpty)
              Center(
                child: Text(
                  _ctrl.searchQuery.value.isNotEmpty
                      ? 'No results for "${_ctrl.searchQuery.value}".'
                      : 'No dealers found.\nTap + to add one.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
              )
            else
              RefreshIndicator(
                onRefresh: _ctrl.loadDealers,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final dealer = list[i];
                    return DealerCard(
                      key: ValueKey(dealer.id),
                      dealer: dealer,
                      balance: _ctrl.balances[dealer.id] ?? 0,
                      onTap: () => Get.toNamed(
                          AppRoutes.dealerLedger,
                          arguments: dealer),
                      onEdit: () async {
                        final result = await Get.toNamed(
                            AppRoutes.addDealer,
                            arguments: dealer);
                        if (result is String && result.isNotEmpty) {
                          Get.snackbar('Updated', '$result updated',
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                      onDelete: () => _confirmDelete(dealer),
                    );
                  },
                ),
              ),

            if (isDeleting)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Deleting dealer...',
                              style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
      floatingActionButton: Obx(() => FloatingActionButton(
            onPressed: _ctrl.isDeleting.value
                ? null
                : () async {
                    final result = await Get.toNamed(
                        AppRoutes.addDealer,
                        arguments: null);
                    if (result == true) {
                      Get.snackbar('Success', 'Dealer added',
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
            child: const Icon(Icons.add),
          )),
    );
  }
}
