import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dealer_controller.dart';
import '../models/dealer_model.dart';
import '../routes/app_routes.dart';
import '../widgets/dealer_card.dart';

class DealerListScreen extends StatelessWidget {
  const DealerListScreen({super.key});

  DealerController get _ctrl => Get.find()..searchQuery.value = '';

  Future<void> _confirmDelete(BuildContext context, DealerModel dealer) async {
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
    final ctrl = _ctrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => ctrl.searchQuery.value = v,
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
        final isDeleting = ctrl.isDeleting.value;
        final isLoading = ctrl.isLoading.value;
        final list = ctrl.filteredDealers;

        return Stack(
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (list.isEmpty)
              const Center(
                child: Text(
                  'No dealers found.\nTap + to add one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              )
            else
              RefreshIndicator(
                onRefresh: ctrl.loadDealers,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final dealer = list[i];
                    return DealerCard(
                      key: ValueKey(dealer.id),
                      dealer: dealer,
                      balance: ctrl.balances[dealer.id] ?? 0,
                      onTap: () => Get.toNamed(
                          AppRoutes.dealerLedger,
                          arguments: dealer),
                      onEdit: () => Get.toNamed(
                          AppRoutes.addDealer,
                          arguments: dealer),
                      onDelete: () => _confirmDelete(ctx, dealer),
                    );
                  },
                ),
              ),

            // Blocking overlay while deleting
            if (isDeleting)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
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
                    final added = await Get.toNamed(
                        AppRoutes.addDealer,
                        arguments: null);
                    if (added == true) {
                      Get.snackbar(
                        'Success',
                        'Dealer added',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
            child: const Icon(Icons.add),
          )),
    );
  }
}
