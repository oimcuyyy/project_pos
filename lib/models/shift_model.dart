class CashShiftModel {
  final int? id;
  final String cashierName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double startingCash;
  final double cashSales;
  final double nonCashSales;
  final double pettyCashOut;
  final double actualCashEnd;
  final double difference;
  final String status; // 'open', 'closed'

  CashShiftModel({
    this.id,
    required this.cashierName,
    required this.openedAt,
    this.closedAt,
    required this.startingCash,
    this.cashSales = 0,
    this.nonCashSales = 0,
    this.pettyCashOut = 0,
    this.actualCashEnd = 0,
    this.difference = 0,
    this.status = 'open',
  });

  double get expectedCashEnd => startingCash + cashSales - pettyCashOut;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cashier_name': cashierName,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'starting_cash': startingCash,
      'cash_sales': cashSales,
      'non_cash_sales': nonCashSales,
      'petty_cash_out': pettyCashOut,
      'actual_cash_end': actualCashEnd,
      'difference': difference,
      'status': status,
    };
  }

  factory CashShiftModel.fromMap(Map<String, dynamic> map) {
    return CashShiftModel(
      id: (map['id'] as num?)?.toInt(),
      cashierName: map['cashier_name']?.toString() ?? 'Kasir',
      openedAt: map['opened_at'] != null ? DateTime.tryParse(map['opened_at'].toString()) ?? DateTime.now() : DateTime.now(),
      closedAt: map['closed_at'] != null ? DateTime.tryParse(map['closed_at'].toString()) : null,
      startingCash: (map['starting_cash'] as num?)?.toDouble() ?? 0.0,
      cashSales: (map['cash_sales'] as num?)?.toDouble() ?? 0.0,
      nonCashSales: (map['non_cash_sales'] as num?)?.toDouble() ?? 0.0,
      pettyCashOut: (map['petty_cash_out'] as num?)?.toDouble() ?? 0.0,
      actualCashEnd: (map['actual_cash_end'] as num?)?.toDouble() ?? 0.0,
      difference: (map['difference'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'open',
    );
  }
}
