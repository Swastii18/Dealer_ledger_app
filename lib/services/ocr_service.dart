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
  Future<OcrResult> extractFromImage(File imageFile) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await recognizer.processImage(inputImage);
      final raw = recognized.text;

      // Normalize: trim each line, remove blanks
      final lines = raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      return OcrResult(
        rawText: raw,
        billNo: _extractBillNo(lines),
        date: _extractDate(lines),
        amount: _extractAmount(lines),
      );
    } finally {
      await recognizer.close();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INVOICE NUMBER
  // Strategy: find a line whose TEXT matches an invoice-label pattern,
  // then grab the number from the same line or the very next line.
  // ─────────────────────────────────────────────────────────────────────────

  String _extractBillNo(List<String> lines) {
    // Matches labels like:  Invoice No:  /  Bill No.  /  Inv#  /  Receipt No
    final labelRe = RegExp(
      r'^(?:tax\s+)?(?:invoice|bill|inv|receipt|voucher|challan|order)'
      r'(?:\s*(?:no\.?|num\.?|number|#))?\s*[:\-#]?\s*',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!labelRe.hasMatch(line)) continue;

      // Value on the same line (after the label)
      final afterLabel = line.replaceFirst(labelRe, '').trim();
      if (afterLabel.isNotEmpty && _validBillNo(afterLabel)) {
        return afterLabel;
      }

      // Value on the next line
      if (i + 1 < lines.length) {
        final next = lines[i + 1].trim();
        if (_validBillNo(next)) return next;
      }
    }

    // Fallback: look for a standalone value that looks like "INV/2024/001"
    final standalonRe =
        RegExp(r'\b((?:[A-Z]{2,5}[-/]?\d{2,10}(?:[-/]\d+)?))\b',
            caseSensitive: false);
    for (final line in lines) {
      final m = standalonRe.firstMatch(line);
      if (m != null && _validBillNo(m.group(1)!)) return m.group(1)!;
    }

    return '';
  }

  bool _validBillNo(String s) {
    if (s.length < 2 || s.length > 25) return false;
    if (!RegExp(r'\d').hasMatch(s)) return false; // must have a digit
    if (RegExp(r'^\d{10}$').hasMatch(s)) return false; // phone number
    // GST number pattern
    if (RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z][A-Z\d]$',
            caseSensitive: false)
        .hasMatch(s)) { return false; }
    // Looks like a date
    if (RegExp(r'^\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}$').hasMatch(s)) {
      return false;
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATE
  // ─────────────────────────────────────────────────────────────────────────

  String _extractDate(List<String> lines) {
    final text = lines.join('\n');

    // "12 Jan 2024" / "12-Jan-24"
    final textMonth = RegExp(
        r'\b(\d{1,2})[\s\-]?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)'
        r'[a-z]*[\s\-,]*(\d{2,4})\b',
        caseSensitive: false);
    // yyyy-mm-dd
    final ymd = RegExp(r'\b(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})\b');
    // dd/mm/yyyy
    final dmy = RegExp(r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})\b');

    final mT = textMonth.firstMatch(text);
    if (mT != null) {
      var y = mT.group(3)!;
      if (y.length == 2) y = '20$y';
      return '$y-${_mon(mT.group(2)!)}-${mT.group(1)!.padLeft(2, '0')}';
    }

    final mY = ymd.firstMatch(text);
    if (mY != null) {
      return '${mY.group(1)!}-${mY.group(2)!.padLeft(2, '0')}-${mY.group(3)!.padLeft(2, '0')}';
    }

    final mD = dmy.firstMatch(text);
    if (mD != null) {
      var y = mD.group(3)!;
      if (y.length == 2) y = '20$y';
      return '$y-${mD.group(2)!.padLeft(2, '0')}-${mD.group(1)!.padLeft(2, '0')}';
    }

    return '';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AMOUNT
  // Three passes in order of reliability:
  //   1. "Amount in words" line  → parse word-number
  //   2. Total/payable label line → grab the number on same or next line
  //   3. Last ₹/Rs. prefixed number in the bill
  // ─────────────────────────────────────────────────────────────────────────

  double? _extractAmount(List<String> lines) {
    // ── Pass 1: Amount in words ──────────────────────────────────────────
    // Matches: "Rupees Five Thousand Only" / "In Words: Three Hundred Only"
    final wordsLabelRe = RegExp(
      r'^(?:(?:amount\s+)?in\s+words?|rupees?|rs\.?)\s*:?\s*(.+)',
      caseSensitive: false,
    );
    for (int i = 0; i < lines.length; i++) {
      // Same line: "Rupees: Five Thousand Only"
      final m = wordsLabelRe.firstMatch(lines[i]);
      if (m != null) {
        final words = m.group(1)!
            .replaceAll(RegExp(r'\bonly\b', caseSensitive: false), '')
            .replaceAll(RegExp(r'\brupees?\b', caseSensitive: false), '')
            .trim();
        if (words.isNotEmpty) {
          final v = _wordsToAmount(words);
          if (v != null && v > 0) return v;
        }
      }
      // Label alone, words on next line
      if (RegExp(r'^(?:amount\s+in\s+words?|in\s+words?)\s*:?\s*$',
              caseSensitive: false)
          .hasMatch(lines[i]) &&
          i + 1 < lines.length) {
        final v = _wordsToAmount(lines[i + 1]);
        if (v != null && v > 0) return v;
      }
    }

    // ── Pass 2: Total / payable label ────────────────────────────────────
    // Strong labels — match reliably with any trailing number
    final strongLabelRe = RegExp(
      r'(?:grand\s*total|net\s*total|total\s*amount|amount\s*due|'
      r'net\s*payable|payable\s*amount|balance\s*due|total\s*payable|'
      r'bill\s*amount|invoice\s*amount|total\s*bill)',
      caseSensitive: false,
    );
    // Weak label — bare "total" alone; only use if it is the only number on line
    final weakLabelRe = RegExp(r'(?<![a-z])total(?![a-z])', caseSensitive: false);

    // Number pattern: handles 5200 / 5,200 / 5,200.00 / 5200/- / ₹5,200
    final numRe = RegExp(
      r'(?:₹|rs\.?\s*)?(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?'
      r'|\d+(?:\.\d{1,2})?)(?:\s*/-)?',
      caseSensitive: false,
    );

    // First scan strong labels
    for (int i = 0; i < lines.length; i++) {
      if (!strongLabelRe.hasMatch(lines[i])) continue;

      // Numbers on the same line — take the rightmost
      final same = numRe.allMatches(lines[i]).toList();
      for (final m in same.reversed) {
        final v = _parseNum(m.group(1)!);
        if (v != null && v > 0 && !_isNonAmount(v)) return v;
      }

      // Number on the very next line
      if (i + 1 < lines.length) {
        final next = numRe.allMatches(lines[i + 1]).toList();
        for (final m in next.reversed) {
          final v = _parseNum(m.group(1)!);
          if (v != null && v > 0 && !_isNonAmount(v)) return v;
        }
      }
    }

    // Then scan weak "total" label — only use when there is exactly one number on the line
    for (int i = 0; i < lines.length; i++) {
      if (!weakLabelRe.hasMatch(lines[i])) continue;

      final same = numRe.allMatches(lines[i]).toList();
      if (same.length == 1) {
        final v = _parseNum(same.first.group(1)!);
        if (v != null && v > 0 && !_isNonAmount(v)) return v;
      }

      if (i + 1 < lines.length) {
        final next = numRe.allMatches(lines[i + 1]).toList();
        if (next.length == 1) {
          final v = _parseNum(next.first.group(1)!);
          if (v != null && v > 0 && !_isNonAmount(v)) return v;
        }
      }
    }

    // ── Pass 3: Last ₹ / Rs. prefixed number ────────────────────────────
    final rsRe = RegExp(
      r'(?:₹|rs\.?\s*)(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?'
      r'|\d+(?:\.\d{1,2})?)(?:\s*/-)?',
      caseSensitive: false,
    );
    double? last;
    for (final line in lines) {
      for (final m in rsRe.allMatches(line)) {
        final v = _parseNum(m.group(1)!);
        if (v != null && v > 0 && !_isNonAmount(v)) last = v;
      }
    }
    if (last != null) return last;

    return null; // leave field blank — better than a wrong value
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AMOUNT IN WORDS  (Indian number system)
  // e.g. "Five Thousand Three Hundred Twenty Five" → 5325
  // ─────────────────────────────────────────────────────────────────────────

  double? _wordsToAmount(String raw) {
    final s = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\bonly\b'), '')
        .replaceAll(RegExp(r'\brupees?\b'), '')
        .replaceAll(RegExp(r'\bpaise?\b'), '')
        .replaceAll(RegExp(r'\brs\b'), '')
        .trim();

    if (s.isEmpty) return null;
    try {
      final result = _parseWordNum(
          s.split(RegExp(r'[\s,\-]+'))
           .where((w) => w.isNotEmpty)
           .toList());
      return result > 0 ? result.toDouble() : null;
    } catch (_) {
      return null;
    }
  }

  int _parseWordNum(List<String> words) {
    const ones = {
      'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
      'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
      'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
      'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
      'eighteen': 18, 'nineteen': 19,
    };
    const tens = {
      'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
      'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
    };
    const multipliers = {
      'hundred': 100,
      'thousand': 1000,
      'lakh': 100000, 'lakhs': 100000, 'lac': 100000, 'lacs': 100000,
      'crore': 10000000, 'crores': 10000000,
      'million': 1000000,
    };

    int total = 0;
    int current = 0;

    for (final w in words) {
      if (ones.containsKey(w)) {
        current += ones[w]!;
      } else if (tens.containsKey(w)) {
        current += tens[w]!;
      } else if (w == 'hundred') {
        if (current == 0) current = 1;
        current *= 100;
      } else if (multipliers.containsKey(w)) {
        if (current == 0) current = 1;
        total += current * multipliers[w]!;
        current = 0;
      }
    }
    return total + current;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  bool _isNonAmount(double v) {
    if (v >= 6000000000 && v <= 9999999999) return true; // mobile number
    if (v >= 100000000000) return true;                   // account number
    return false;
  }

  double? _parseNum(String s) =>
      double.tryParse(s.replaceAll(',', '').replaceAll('/-', '').trim());

  String _mon(String abbr) {
    const m = {
      'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04',
      'may': '05', 'jun': '06', 'jul': '07', 'aug': '08',
      'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12',
    };
    return m[abbr.toLowerCase()] ?? '01';
  }
}
