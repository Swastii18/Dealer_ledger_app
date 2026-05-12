import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/ledger_controller.dart';
import '../models/dealer_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final LedgerController _ctrl = Get.find();
  late final DealerModel _dealer;
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String _paymentType = 'cash';
  bool _saving = false;

  final List<Map<String, String>> _paymentTypes = const [
    {'value': 'cash', 'label': 'Cash'},
    {'value': 'bank', 'label': 'Bank Transfer'},
    {'value': 'upi', 'label': 'UPI'},
    {'value': 'cheque', 'label': 'Cheque'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _dealer = Get.arguments as DealerModel;
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await _ctrl.addPaymentEntry(
      dealerId: _dealer.id!,
      date: _dateCtrl.text,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      paymentType: _paymentType,
      remarks: _remarksCtrl.text,
    );
    setState(() => _saving = false);
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Payment – ${_dealer.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current balance
              Obx(() => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.creditColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.creditColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Balance Due',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          fmtAmount(_ctrl.currentBalance),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _ctrl.currentBalance > 0
                                ? AppTheme.debitColor
                                : AppTheme.creditColor,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (₹) *',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  if ((double.tryParse(v) ?? 0) <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Payment Date *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Date is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentType,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _paymentTypes
                    .map((t) => DropdownMenuItem(
                        value: t['value'], child: Text(t['label']!)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksCtrl,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.creditColor),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle),
                label: const Text('Record Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
