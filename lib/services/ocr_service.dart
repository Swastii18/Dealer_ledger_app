import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final String billNo;
  final String date;
  final double? amount;

  const OcrResult({
    required this.rawText,
    required this.billNo,
    required this.date,
    this.amount,
  });
}

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> extractFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);
    final text = recognized.text;
    return OcrResult(
      rawText: text,
      billNo: _extractBillNo(text),
      date: _extractDate(text),
      amount: _extractAmount(text),
    );
  }

  void dispose() => _recognizer.close();

  // ── Extractors ────────────────────────────────────────────────────────────

  String _extractBillNo(String text) {
    // Matches: Invoice No: 1234 / Bill No. ABC-123 / Invoice# INV2024 / No: 456
    final patterns = [
      RegExp(
          r'(?:invoice|bill|inv|receipt|voucher|challan)\s*(?:no|num|number|#|\.)\s*[:\-]?\s*([A-Z0-9][\w\-/]{0,20})',
          caseSensitive: false),
      RegExp(r'(?:no|num)\s*[:\-]\s*([A-Z0-9][\w\-/]{0,20})',
          caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null && m.group(1) != null) return m.group(1)!.trim();
    }
    return '';
  }

  String _extractDate(String text) {
    // dd/mm/yyyy  dd-mm-yyyy  dd.mm.yyyy
    final dmy = RegExp(r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})\b');
    // yyyy-mm-dd
    final ymd = RegExp(r'\b(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})\b');
    // 12 Jan 2024 / 12-Jan-24
    final textMonth = RegExp(
        r'\b(\d{1,2})[\s\-]?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s\-,]*(\d{2,4})\b',
        caseSensitive: false);

    final mText = textMonth.firstMatch(text);
    if (mText != null) {
      final day = mText.group(1)!.padLeft(2, '0');
      final mon = _monthNum(mText.group(2)!);
      var year = mText.group(3)!;
      if (year.length == 2) year = '20$year';
      return '$year-$mon-$day';
    }

    final mYmd = ymd.firstMatch(text);
    if (mYmd != null) {
      final y = mYmd.group(1)!;
      final mo = mYmd.group(2)!.padLeft(2, '0');
      final d = mYmd.group(3)!.padLeft(2, '0');
      return '$y-$mo-$d';
    }

    final mDmy = dmy.firstMatch(text);
    if (mDmy != null) {
      final d = mDmy.group(1)!.padLeft(2, '0');
      final mo = mDmy.group(2)!.padLeft(2, '0');
      var y = mDmy.group(3)!;
      if (y.length == 2) y = '20$y';
      return '$y-$mo-$d';
    }

    return '';
  }

  double? _extractAmount(String text) {
    // Priority: lines containing Total / Grand Total / Net / Amount Due / Payable
    final priorityLine = RegExp(
        r'(?:grand\s*total|net\s*total|total\s*amount|amount\s*due|payable|total)[^\d]*(\d[\d,]*\.?\d*)',
        caseSensitive: false);
    final m = priorityLine.firstMatch(text);
    if (m != null) return _parseAmount(m.group(1)!);

    // Fallback: largest number in the text (likely the total)
    final allNums = RegExp(r'\b(\d[\d,]*\.?\d{0,2})\b');
    double? largest;
    for (final m2 in allNums.allMatches(text)) {
      final v = _parseAmount(m2.group(1)!);
      if (v != null && (largest == null || v > largest)) largest = v;
    }
    return largest;
  }

  double? _parseAmount(String s) {
    final cleaned = s.replaceAll(',', '');
    return double.tryParse(cleaned);
  }

  String _monthNum(String abbr) {
    const map = {
      'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04',
      'may': '05', 'jun': '06', 'jul': '07', 'aug': '08',
      'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12',
    };
    return map[abbr.toLowerCase()] ?? '01';
  }
}
