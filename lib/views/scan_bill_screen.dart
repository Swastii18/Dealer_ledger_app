import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ledger_controller.dart';
import '../controllers/ocr_controller.dart';
import '../models/dealer_model.dart';
import '../theme/app_theme.dart';

class ScanBillScreen extends StatefulWidget {
  const ScanBillScreen({super.key});

  @override
  State<ScanBillScreen> createState() => _ScanBillScreenState();
}

class _ScanBillScreenState extends State<ScanBillScreen> {
  final OcrController _ocr = Get.find();
  final LedgerController _ledger = Get.find();
  late final DealerModel _dealer;

  final _formKey = GlobalKey<FormState>();
  final _billNoCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  bool _saving = false;

  // Workers to auto-fill form whenever OCR extracts new values
  late final Worker _billNoWorker;
  late final Worker _dateWorker;
  late final Worker _amountWorker;

  @override
  void initState() {
    super.initState();
    _dealer = Get.arguments as DealerModel;
    _ocr.reset();
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _billNoWorker = ever(_ocr.extractedBillNo, (val) {
      if (val.isNotEmpty) _billNoCtrl.text = val;
    });
    _dateWorker = ever(_ocr.extractedDate, (val) {
      if (val.isNotEmpty) _dateCtrl.text = val;
    });
    _amountWorker = ever(_ocr.extractedAmount, (val) {
      if (val > 0) _amountCtrl.text = val.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _billNoWorker.dispose();
    _dateWorker.dispose();
    _amountWorker.dispose();
    _billNoCtrl.dispose();
    _dateCtrl.dispose();
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await _ledger.addBillEntry(
      dealerId: _dealer.id!,
      date: _dateCtrl.text,
      billNo: _billNoCtrl.text,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      remarks: _remarksCtrl.text,
    );
    setState(() => _saving = false);
    if (ok) Get.back();
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _ocr.pickFromCamera();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _ocr.pickFromGallery();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Bill – ${_dealer.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image picker + OCR status ──────────────────────────────
            Obx(() {
              final image = _ocr.selectedImage.value;
              final processing = _ocr.isProcessing.value;

              return GestureDetector(
                onTap: processing ? null : _showImageOptions,
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (image != null)
                          Image.file(image, fit: BoxFit.cover)
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.document_scanner,
                                  size: 52, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Tap to scan bill',
                                  style: TextStyle(color: Colors.grey[500],
                                      fontSize: 15)),
                              Text('(camera or gallery)',
                                  style: TextStyle(color: Colors.grey[400],
                                      fontSize: 12)),
                            ],
                          ),

                        // Processing overlay
                        if (processing)
                          Container(
                            color: Colors.black54,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                    color: Colors.white),
                                SizedBox(height: 12),
                                Text('Reading bill...',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // OCR success banner
            Obx(() {
              if (!_ocr.hasExtraction.value || _ocr.isProcessing.value) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bill scanned — fields filled below. Edit if needed.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // ── Form ──────────────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _billNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bill / Invoice Number',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _dateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_dateCtrl.text) ??
                            DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        _dateCtrl.text =
                            DateFormat('yyyy-MM-dd').format(picked);
                      }
                    },
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Date is required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bill Amount (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Amount is required';
                      if ((double.tryParse(v) ?? 0) <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _remarksCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_saving || _ocr.isProcessing.value)
                              ? null
                              : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.save),
                          label: const Text('Save as Debit Entry'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.debitColor),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
