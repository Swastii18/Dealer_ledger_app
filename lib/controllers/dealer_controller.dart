import 'package:get/get.dart';
import '../models/dealer_model.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class DealerController extends GetxController {
  final DatabaseService _db = DatabaseService();

  final RxList<DealerModel> dealers = <DealerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  List<DealerModel> get filteredDealers {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return dealers;
    return dealers
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.phone.toLowerCase().contains(q))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadDealers();
  }

  Future<void> loadDealers() async {
    isLoading.value = true;
    dealers.value = await _db.getAllDealers();
    isLoading.value = false;
  }

  Future<bool> addDealer({
    required String name,
    required String phone,
    required String address,
  }) async {
    if (name.trim().isEmpty) {
      Get.snackbar('Error', 'Dealer name is required',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    final dealer = DealerModel(
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim(),
      createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );
    await _db.insertDealer(dealer);
    await loadDealers();
    Get.snackbar('Success', '${dealer.name} added',
        snackPosition: SnackPosition.BOTTOM);
    return true;
  }

  Future<bool> updateDealer({
    required DealerModel dealer,
    required String name,
    required String phone,
    required String address,
  }) async {
    if (name.trim().isEmpty) {
      Get.snackbar('Error', 'Dealer name is required',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    final updated = dealer.copyWith(
        name: name.trim(), phone: phone.trim(), address: address.trim());
    await _db.updateDealer(updated);
    await loadDealers();
    Get.snackbar('Updated', '${updated.name} updated',
        snackPosition: SnackPosition.BOTTOM);
    return true;
  }

  Future<void> deleteDealer(int id, String name) async {
    await _db.deleteDealer(id);
    await loadDealers();
    Get.snackbar('Deleted', '$name deleted',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<double> getDealerBalance(int dealerId) =>
      _db.getDealerBalance(dealerId);
}
