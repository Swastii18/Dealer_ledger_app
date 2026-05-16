import 'package:dealer_ledger_app/services/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OcrService.extractFromText', () {
    test('fills invoice number, labelled date, and after-tax total', () {
      final result = OcrService().extractFromText('''
ABC Traders
Tax Invoice No: INV-2026/104
Invoice Date: 14/05/2026
Total Amount Before Tax 1,000.00
CGST 90.00
SGST 90.00
Grand Total Rs. 1,180.00
''');

      expect(result.billNo, 'INV-2026/104');
      expect(result.date, '2026-05-14');
      expect(result.amount, 1180.00);
    });

    test('ignores subtotal and tax rows when final total is lower in bill', () {
      final result = OcrService().extractFromText('''
Bill # B-778
Date 12-May-26
Subtotal Rs. 2,500.00
GST Rs. 450.00
Total Payable
Rs. 2,950.00
''');

      expect(result.billNo, 'B-778');
      expect(result.date, '2026-05-12');
      expect(result.amount, 2950.00);
    });

    test('uses bottom generic total instead of total before tax', () {
      final result = OcrService().extractFromText('''
Receipt No
RCPT/45
Dt. 01.04.2026
Total Amount Before Tax 700
VAT 91
Total 791
''');

      expect(result.billNo, 'RCPT/45');
      expect(result.date, '2026-04-01');
      expect(result.amount, 791.00);
    });
  });
}
