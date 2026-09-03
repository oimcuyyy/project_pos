import 'cart_item_model.dart';

enum PaymentMethod { cash, transfer, qris }

class TransactionModel {
  final String id;
  final DateTime dateTime;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double serviceCharge;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final double cashReceived;
  final double change;
  final String cashierName;
  final String orderType; // 'Dine In', 'Take Away'
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final String? paymentProofUrl;

  TransactionModel({
    required this.id,
    required this.dateTime,
    required this.items,
    double? subtotal,
    this.discount = 0,
    this.tax = 0,
    this.serviceCharge = 0,
    required this.totalAmount,
    required this.paymentMethod,
    this.cashReceived = 0,
    this.change = 0,
    required this.cashierName,
    this.orderType = 'Dine In',
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.paymentProofUrl,
  }) : subtotal = subtotal ?? items.fold(0.0, (sum, i) => sum + i.subtotal);

  // Total Modal / HPP untuk transaksi ini
  double get totalCost => items.fold(0.0, (sum, i) => sum + (i.product.costPrice * i.quantity));

  // Laba Kotor transaksi ini
  double get grossProfit => totalAmount - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': dateTime.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'service_charge': serviceCharge,
      'total_amount': totalAmount,
      'payment_method': paymentMethod.name,
      'cash_received': cashReceived,
      'change': change,
      'cashier_name': cashierName,
      'order_type': orderType,
      'table_number': tableNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'payment_proof_url': paymentProofUrl,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, {List<CartItemModel>? items}) {
    PaymentMethod method = PaymentMethod.cash;
    if (map['payment_method'] == 'qris') method = PaymentMethod.qris;
    if (map['payment_method'] == 'transfer') method = PaymentMethod.transfer;

    return TransactionModel(
      id: map['id']?.toString() ?? '',
      dateTime: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      items: items ?? [],
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (map['service_charge'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: method,
      cashReceived: (map['cash_received'] as num?)?.toDouble() ?? 0.0,
      change: (map['change'] as num?)?.toDouble() ?? 0.0,
      cashierName: map['cashier_name']?.toString() ?? 'Kasir',
      orderType: map['order_type']?.toString() ?? 'Dine In',
      tableNumber: map['table_number']?.toString(),
      customerName: map['customer_name']?.toString(),
      customerPhone: map['customer_phone']?.toString(),
      paymentProofUrl: map['payment_proof_url']?.toString(),
    );
  }
}
