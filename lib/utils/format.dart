import 'package:intl/intl.dart';

final _amountFmt = NumberFormat('#,##0.00', 'en_IN');

String fmtAmount(double v) => '₹${_amountFmt.format(v)}';
