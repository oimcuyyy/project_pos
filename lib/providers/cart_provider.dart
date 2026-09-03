import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class HeldOrder {
  final String id;
  final String label; // e.g. "Meja 3" or "Pesanan #2"
  final DateTime heldAt;
  final Map<String, CartItemModel> items;
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final double discountAmount;
  final double discountPercent;

  HeldOrder({
    required this.id,
    required this.label,
    required this.heldAt,
    required this.items,
    required this.orderType,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.discountAmount = 0,
    this.discountPercent = 0,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItemModel> _items = {};
  final List<HeldOrder> _heldOrders = [];

  // Order Details
  String _orderType = 'Dine In'; // 'Dine In' or 'Take Away'
  String? _tableNumber;
  String? _customerName;
  String? _customerPhone;

  // Discounts & Charges
  double _discountAmount = 0.0;
  double _discountPercent = 0.0;
  double _taxPercent = 0.0;
  double _serviceChargePercent = 0.0;

  Map<String, CartItemModel> get items => _items;
  List<CartItemModel> get itemList => _items.values.toList();
  List<HeldOrder> get heldOrders => List.unmodifiable(_heldOrders);

  String get orderType => _orderType;
  String? get tableNumber => _tableNumber;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;

  double get discountAmount => _discountAmount;
  double get discountPercent => _discountPercent;
  double get taxPercent => _taxPercent;
  double get serviceChargePercent => _serviceChargePercent;

  int get totalItemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  // Subtotal sebelum diskon & pajak
  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  // Nilai diskon dalam Rupiah
  double get discountValue {
    if (_discountPercent > 0) {
      return (subtotal * (_discountPercent / 100)).clamp(0, subtotal);
    }
    return _discountAmount.clamp(0, subtotal);
  }

  // Dasar pengenaan pajak (setelah diskon)
  double get afterDiscount => (subtotal - discountValue).clamp(0, double.infinity);

  // Nilai Pajak
  double get taxValue => afterDiscount * (_taxPercent / 100);

  // Nilai Biaya Layanan
  double get serviceChargeValue => afterDiscount * (_serviceChargePercent / 100);

  // Grand Total Akhir
  double get grandTotal => afterDiscount + taxValue + serviceChargeValue;

  // Compatibility getter
  double get totalPrice => grandTotal;

  // Setters
  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void setTableNumber(String? table) {
    _tableNumber = table;
    notifyListeners();
  }

  void setCustomerInfo(String? name, String? phone) {
    _customerName = name;
    _customerPhone = phone;
    notifyListeners();
  }

  void setDiscount({double amount = 0.0, double percent = 0.0}) {
    _discountAmount = amount;
    _discountPercent = percent;
    notifyListeners();
  }

  void setTaxAndService({double tax = 0.0, double service = 0.0}) {
    _taxPercent = tax;
    _serviceChargePercent = service;
    notifyListeners();
  }

  void addItem(ProductModel product, {List<Map<String, dynamic>> options = const []}) {
    if (product.stock <= 0) return;

    final currentProductTotal = _items.values
        .where((i) => i.product.id == product.id)
        .fold(0, (sum, i) => sum + i.quantity);
    if (currentProductTotal >= product.stock) return;

    final cartItemId = CartItemModel.generateId(product.id, options);

    if (_items.containsKey(cartItemId)) {
      _items[cartItemId]!.quantity += 1;
    } else {
      _items[cartItemId] = CartItemModel(
        product: product, 
        quantity: 1,
        selectedOptions: options,
        uniqueId: cartItemId,
      );
    }
    notifyListeners();
  }

  void decreaseQuantity(String cartItemId) {
    if (!_items.containsKey(cartItemId)) return;
    if (_items[cartItemId]!.quantity > 1) {
      _items[cartItemId]!.quantity -= 1;
    } else {
      _items.remove(cartItemId);
    }
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.remove(cartItemId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discountAmount = 0.0;
    _discountPercent = 0.0;
    _tableNumber = null;
    _customerName = null;
    _customerPhone = null;
    _orderType = 'Dine In';
    notifyListeners();
  }

  // ================= SIMPAN PESANAN (HOLD / PARK ORDER) =================
  bool holdCurrentOrder(String? customLabel) {
    if (_items.isEmpty) return false;

    final label = (customLabel != null && customLabel.trim().isNotEmpty)
        ? customLabel.trim()
        : (_tableNumber != null && _tableNumber!.isNotEmpty)
            ? 'Meja $_tableNumber'
            : 'Order #${_heldOrders.length + 1}';

    final held = HeldOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      heldAt: DateTime.now(),
      items: Map.from(_items.map((k, v) => MapEntry(k, CartItemModel(product: v.product, quantity: v.quantity, selectedOptions: List.from(v.selectedOptions), uniqueId: v.uniqueId)))),
      orderType: _orderType,
      tableNumber: _tableNumber,
      customerName: _customerName,
      customerPhone: _customerPhone,
      discountAmount: _discountAmount,
      discountPercent: _discountPercent,
    );

    _heldOrders.add(held);
    clearCart();
    notifyListeners();
    return true;
  }

  void resumeHeldOrder(HeldOrder held) {
    clearCart();
    _items.addAll(held.items);
    _orderType = held.orderType;
    _tableNumber = held.tableNumber;
    _customerName = held.customerName;
    _customerPhone = held.customerPhone;
    _discountAmount = held.discountAmount;
    _discountPercent = held.discountPercent;
    _heldOrders.removeWhere((o) => o.id == held.id);
    notifyListeners();
  }

  void deleteHeldOrder(String heldId) {
    _heldOrders.removeWhere((o) => o.id == heldId);
    notifyListeners();
  }
}
