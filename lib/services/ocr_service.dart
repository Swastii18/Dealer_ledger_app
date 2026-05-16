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

      return extractFromText(raw);
    } finally {
      await recognizer.close();
    }
  }

  OcrResult extractFromText(String raw) {
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
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INVOICE NUMBER
  // Strategy: find a line whose TEXT matches an invoice-label pattern,
  // then grab the number from the same line or the very next line.
  // ─────────────────────────────────────────────────────────────────────────

  String _extractBillNo(List<String> lines) {
    // Matches labels like: Invoice No, Bill No, Inv#, Receipt #, Tax Invoice No
    final labelRe = RegExp(
      r'\b(?:tax\s+)?(?:invoice|bill|inv|receipt|voucher|challan|order)'
      r'(?:\s*(?:no\.?|num\.?|number|#))?\s*[:\-#]?\s*',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!labelRe.hasMatch(line)) continue;

      // Value on the same line (after the label)
      final afterLabel = line.replaceFirst(labelRe, '').trim();
      final sameLineBillNo = _billNoCandidate(afterLabel);
      if (sameLineBillNo != null) {
        return sameLineBillNo;
      }

      // Value on the next line
      if (i + 1 < lines.length) {
        final nextBillNo = _billNoCandidate(lines[i + 1]);
        if (nextBillNo != null) return nextBillNo;
      }
    }

    // Fallback: look for a standalone value that looks like "INV/2024/001"
    final standalonRe = RegExp(
      r'\b((?:[A-Z]{2,5}[-/]?\d{2,10}(?:[-/]\d+)?))\b',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = standalonRe.firstMatch(line);
      if (m != null && _validBillNo(m.group(1)!)) return m.group(1)!;
    }

    return '';
  }

  String? _billNoCandidate(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'\bdate\b.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bdt\.?\b.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;

    if (_validBillNo(cleaned)) return cleaned;

    final tokenRe = RegExp(r'[A-Z0-9][A-Z0-9./_-]{1,24}', caseSensitive: false);
    for (final match in tokenRe.allMatches(cleaned)) {
      final token = match
          .group(0)!
          .replaceAll(RegExp(r'^[#:\-]+|[#:\-]+$'), '');
      if (_validBillNo(token)) return token;
    }

    return null;
  }

  bool _validBillNo(String s) {
    if (s.length < 2 || s.length > 25) return false;
    if (!RegExp(r'\d').hasMatch(s)) return false; // must have a digit
    if (RegExp(r'^\d{10}$').hasMatch(s)) return false; // phone number
    // GST number pattern
    if (RegExp(
      r'^\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z][A-Z\d]$',
      caseSensitive: false,
    ).hasMatch(s)) {
      return false;
    }
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
      caseSensitive: false,
    );
    // yyyy-mm-dd
    final ymd = RegExp(r'\b(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})\b');
    // dd/mm/yyyy
    final dmy = RegExp(r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})\b');

    final dateLabelRe = RegExp(
      r'\b(?:invoice|bill|receipt|order)?\s*(?:date|dt\.?)\b',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (!dateLabelRe.hasMatch(line)) continue;

      final labelledTextMonth = textMonth.firstMatch(line);
      if (labelledTextMonth != null) {
        var y = labelledTextMonth.group(3)!;
        if (y.length == 2) y = '20$y';
        return '$y-${_mon(labelledTextMonth.group(2)!)}-${labelledTextMonth.group(1)!.padLeft(2, '0')}';
      }

      final labelledYmd = ymd.firstMatch(line);
      if (labelledYmd != null) {
        return '${labelledYmd.group(1)!}-${labelledYmd.group(2)!.padLeft(2, '0')}-${labelledYmd.group(3)!.padLeft(2, '0')}';
      }

      final labelledDmy = dmy.firstMatch(line);
      if (labelledDmy != null) {
        final formatted = _formatDmyDate(labelledDmy);
        if (formatted != null) return formatted;
      }
    }

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
      final formatted = _formatDmyDate(mD);
      if (formatted != null) return formatted;
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
        final words = m
            .group(1)!
            .replaceAll(RegExp(r'\bonly\b', caseSensitive: false), '')
            .replaceAll(RegExp(r'\brupees?\b', caseSensitive: false), '')
            .trim();
        if (words.isNotEmpty) {
          final v = _wordsToAmount(words);
          if (v != null && v > 0) return v;
        }
      }
      // Label alone, words on next line
      if (RegExp(
            r'^(?:amount\s+in\s+words?|in\s+words?)\s*:?\s*$',
            caseSensitive: false,
          ).hasMatch(lines[i]) &&
          i + 1 < lines.length) {
        final v = _wordsToAmount(lines[i + 1]);
        if (v != null && v > 0) return v;
      }
    }

    // ── Pass 2: final total / payable label ──────────────────────────────
    // Prefer after-tax payable labels and reject subtotal/tax rows.
    final finalLabelRe = RegExp(
      r'(?:grand\s*total|net\s*total|net\s*amount|net\s*payable|'
      r'payable\s*amount|amount\s*payable|amount\s*due|balance\s*due|'
      r'total\s*payable|total\s*due|invoice\s*value|invoice\s*amount|'
      r'bill\s*amount|total\s*bill|total\s*invoice\s*value|'
      r'total\s*amount\s*(?:after|including|incl\.?)\s*tax|'
      r'total\s*(?:after|including|incl\.?)\s*tax|round\s*off\s*total)',
      caseSensitive: false,
    );
    final genericTotalRe = RegExp(
      r'(?<![a-z])(?:total\s*amount|total)(?![a-z])',
      caseSensitive: false,
    );
    final preTaxOrTaxLineRe = RegExp(
      r'(?:sub\s*total|subtotal|taxable|before\s*tax|pre\s*tax|'
      r'basic\s*amount|gross\s*amount|discount|cgst|sgst|igst|gst|vat|'
      r'tax\s*amount|amount\s*before)',
      caseSensitive: false,
    );
    // Weak label — bare "total" alone; only use if it is the only number on line
    final weakLabelRe = RegExp(
      r'(?<![a-z])total(?![a-z])',
      caseSensitive: false,
    );

    // Number pattern: handles 5200 / 5,200 / 5,200.00 / 5200/- / ₹5,200
    final numRe = RegExp(
      r'(?:₹|rs\.?\s*)?(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?'
      r'|\d+(?:\.\d{1,2})?)(?:\s*/-)?',
      caseSensitive: false,
    );

    // First scan final labels from the bottom. Bills usually print totals after
    // tax rows, and bottom-up avoids accepting "Total Amount Before Tax".
    for (int i = 0; i < lines.length; i++) {
      final line = lines[lines.length - 1 - i];
      if (!finalLabelRe.hasMatch(line) ||
          _isPreTaxOrTaxLine(line, preTaxOrTaxLineRe)) {
        continue;
      }

      // Numbers on the same line — take the rightmost
      final same = numRe.allMatches(line).toList();
      for (final m in same.reversed) {
        final v = _parseNum(m.group(1)!);
        if (v != null && v > 0 && !_isNonAmount(v)) return v;
      }

      final originalIndex = lines.length - 1 - i;
      final nearby = _nearbyAmount(
        lines,
        originalIndex,
        numRe,
        preTaxOrTaxLineRe,
      );
      if (nearby != null) return nearby;
    }

    // Then scan generic total labels, still skipping tax and before-tax rows.
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (!genericTotalRe.hasMatch(line) ||
          _isPreTaxOrTaxLine(line, preTaxOrTaxLineRe)) {
        continue;
      }

      final same = numRe.allMatches(line).toList();
      for (final m in same.reversed) {
        final v = _parseNum(m.group(1)!);
        if (v != null && v > 0 && !_isNonAmount(v)) return v;
      }

      final nearby = _nearbyAmount(lines, i, numRe, preTaxOrTaxLineRe);
      if (nearby != null) return nearby;
    }

    // Then scan weak "total" label — only use when there is exactly one number on the line
    for (int i = 0; i < lines.length; i++) {
      if (!weakLabelRe.hasMatch(lines[i]) ||
          _isPreTaxOrTaxLine(lines[i], preTaxOrTaxLineRe)) {
        continue;
      }

      final same = numRe.allMatches(lines[i]).toList();
      if (same.length == 1) {
        final v = _parseNum(same.first.group(1)!);
        if (v != null && v > 0 && !_isNonAmount(v)) return v;
      }

      if (i + 1 < lines.length) {
        if (_isPreTaxOrTaxLine(lines[i + 1], preTaxOrTaxLineRe)) continue;
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

  bool _isPreTaxOrTaxLine(String line, RegExp preTaxOrTaxLineRe) =>
      preTaxOrTaxLineRe.hasMatch(line) &&
      !RegExp(
        r'(?:after|including|incl\.?)\s*tax',
        caseSensitive: false,
      ).hasMatch(line);

  double? _nearbyAmount(
    List<String> lines,
    int labelIndex,
    RegExp numRe,
    RegExp preTaxOrTaxLineRe,
  ) {
    for (final index in [labelIndex + 1, labelIndex - 1]) {
      if (index < 0 || index >= lines.length) continue;
      if (_isPreTaxOrTaxLine(lines[index], preTaxOrTaxLineRe)) continue;

      final matches = numRe.allMatches(lines[index]).toList();
      for (final match in matches.reversed) {
        final v = _parseNum(match.group(1)!);
        if (v != null && v > 0 && !_isNonAmount(v)) return v;
      }
    }
    return null;
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
        s.split(RegExp(r'[\s,\-]+')).where((w) => w.isNotEmpty).toList(),
      );
      return result > 0 ? result.toDouble() : null;
    } catch (_) {
      return null;
    }
  }

  int _parseWordNum(List<String> words) {
    const ones = {
      'zero': 0,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'thirteen': 13,
      'fourteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
    };
    const tens = {
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'fifty': 50,
      'sixty': 60,
      'seventy': 70,
      'eighty': 80,
      'ninety': 90,
    };
    const multipliers = {
      'hundred': 100,
      'thousand': 1000,
      'lakh': 100000,
      'lakhs': 100000,
      'lac': 100000,
      'lacs': 100000,
      'crore': 10000000,
      'crores': 10000000,
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
    if (v >= 100000000000) return true; // account number
    return false;
  }

  double? _parseNum(String s) =>
      double.tryParse(s.replaceAll(',', '').replaceAll('/-', '').trim());

  String? _formatDmyDate(RegExpMatch match) {
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (day == null ||
        month == null ||
        day < 1 ||
        day > 31 ||
        month < 1 ||
        month > 12) {
      return null;
    }

    var year = match.group(3)!;
    if (year.length == 2) year = '20$year';
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String _mon(String abbr) {
    const m = {
      'jan': '01',
      'feb': '02',
      'mar': '03',
      'apr': '04',
      'may': '05',
      'jun': '06',
      'jul': '07',
      'aug': '08',
      'sep': '09',
      'oct': '10',
      'nov': '11',
      'dec': '12',
    };
    return m[abbr.toLowerCase()] ?? '01';
  }
}
