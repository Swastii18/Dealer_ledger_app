class LedgerModel {
  final int? id;
  final int dealerId;
  final String date;
  final String billNo;
  final double debit;
  final double credit;
  final double runningTotal;
  final String paymentType;
  final String remarks;

  LedgerModel({
    this.id,
    required this.dealerId,
    required this.date,
    required this.billNo,
    required this.debit,
    required this.credit,
    required this.runningTotal,
    required this.paymentType,
    required this.remarks,
  });

  bool get isDebit => debit > 0;
  bool get isCredit => credit > 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'dealer_id': dealerId,
        'date': date,
        'bill_no': billNo,
        'debit': debit,
        'credit': credit,
        'running_total': runningTotal,
        'payment_type': paymentType,
        'remarks': remarks,
      };

  factory LedgerModel.fromMap(Map<String, dynamic> map) => LedgerModel(
        id: map['id'],
        dealerId: map['dealer_id'],
        date: map['date'],
        billNo: map['bill_no'],
        debit: (map['debit'] as num).toDouble(),
        credit: (map['credit'] as num).toDouble(),
        runningTotal: (map['running_total'] as num).toDouble(),
        paymentType: map['payment_type'],
        remarks: map['remarks'],
      );

  LedgerModel copyWith({
    int? id,
    int? dealerId,
    String? date,
    String? billNo,
    double? debit,
    double? credit,
    double? runningTotal,
    String? paymentType,
    String? remarks,
  }) =>
      LedgerModel(
        id: id ?? this.id,
        dealerId: dealerId ?? this.dealerId,
        date: date ?? this.date,
        billNo: billNo ?? this.billNo,
        debit: debit ?? this.debit,
        credit: credit ?? this.credit,
        runningTotal: runningTotal ?? this.runningTotal,
        paymentType: paymentType ?? this.paymentType,
        remarks: remarks ?? this.remarks,
      );
}
