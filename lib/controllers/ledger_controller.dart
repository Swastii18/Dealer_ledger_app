import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/ledger_model.dart';
import '../services/database_service.dart';

class LedgerController extends GetxController {
  final DatabaseService _db = DatabaseService();

  final RxList<LedgerModel> entries = <LedgerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterDate = ''.obs;

  int? _currentDealerId;

  List<LedgerModel> get filteredEntries {
    var list = entries.toList();
    final q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((e) =>
              e.billNo.toLowerCase().contains(q) ||
              e.remarks.toLowerCase().contains(q) ||
              e.date.contains(q))
          .toList();
    }
    if (filterDate.value.isNotEmpty) {
      list = list.where((e) => e.date.startsWith(filterDate.value)).toList();
    }
    return list;
  }

  double get currentBalance {
    if (entries.isEmpty) return 0;
    return entries.last.runningTotal;
  }

  double get totalDebit =>
      entries.fold(0, (sum, e) => sum + e.debit);

  double get totalCredit =>
      entries.fold(0, (sum, e) => sum + e.credit);

  Future<void> loadLedger(int dealerId) async {
    _currentDealerId = dealerId;
    isLoading.value = true;
    entries.value = await _db.getLedgerByDealer(dealerId);
    isLoading.value = false;
  }

  Future<bool> addBillEntry({
    required int dealerId,
    required String date,
    required String billNo,
    required double amount,
    required String remarks,
  }) async {
    if (amount <= 0) {
      Get.snackbar('Error', 'Amount must be greater than 0',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    final lastBalance = await _db.getLastRunningTotal(dealerId);
    final entry = LedgerModel(
      dealerId: dealerId,
      date: date,
      billNo: billNo.trim(),
      debit: amount,
      credit: 0,
      runningTotal: lastBalance + amount,
      paymentType: 'bill',
      remarks: remarks.trim(),
    );
    await _db.insertLedgerEntry(entry);
    await loadLedger(dealerId);
    Get.snackbar('Saved', 'Bill entry saved', snackPosition: SnackPosition.BOTTOM);
    return true;
  }

  Future<bool> addPaymentEntry({
    required int dealerId,
    required String date,
    required double amount,
    required String paymentType,
    required String remarks,
  }) async {
    if (amount <= 0) {
      Get.snackbar('Error', 'Amount must be greater than 0',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    final lastBalance = await _db.getLastRunningTotal(dealerId);
    final entry = LedgerModel(
      dealerId: dealerId,
      date: date,
      billNo: '',
      debit: 0,
      credit: amount,
      runningTotal: lastBalance - amount,
      paymentType: paymentType,
      remarks: remarks.trim(),
    );
    await _db.insertLedgerEntry(entry);
    await loadLedger(dealerId);
    Get.snackbar('Saved', 'Payment recorded', snackPosition: SnackPosition.BOTTOM);
    return true;
  }

  Future<void> deleteLedgerEntry(int entryId) async {
    await _db.deleteLedgerEntry(entryId);
    if (_currentDealerId != null) {
      // Recalculate running totals after deletion
      await _recalculateRunningTotals(_currentDealerId!);
      await loadLedger(_currentDealerId!);
    }
  }

  Future<void> _recalculateRunningTotals(int dealerId) async {
    final allEntries = await _db.getLedgerByDealer(dealerId);
    double running = 0;
    for (final e in allEntries) {
      running = running + e.debit - e.credit;
      await _db.updateLedgerEntry(e.copyWith(runningTotal: running));
    }
  }

  String formatDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
  String today() => formatDate(DateTime.now());
}
