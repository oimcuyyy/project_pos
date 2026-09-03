import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

  TransactionProvider() {
    fetchTransactions();
  }

  // Fetch dari Supabase
  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.client;
      final trxRes = await supabase.from('transactions').select().order('created_at', ascending: false);

      final List<TransactionModel> loaded = [];

      for (var row in trxRes as List) {
        final trxId = row['id'].toString();

        // Fetch detail items per transaksi
        List<CartItemModel> items = [];
        try {
          final itemsRes = await supabase.from('transaction_items').select().eq('transaction_id', trxId);
          items = (itemsRes as List).map((i) {
            final prod = ProductModel(
              id: i['product_id']?.toString() ?? '',
              name: i['product_name']?.toString() ?? '',
              price: (i['price'] as num?)?.toDouble() ?? 0.0,
              costPrice: (i['cost_price'] as num?)?.toDouble() ?? 0.0,
              category: 'General',
              stock: 0,
            );
            List<Map<String, dynamic>> parsedOptions = [];
            if (i['selected_options'] != null) {
              if (i['selected_options'] is List) {
                parsedOptions = List<Map<String, dynamic>>.from(i['selected_options'].map((e) => Map<String, dynamic>.from(e)));
              }
            }
            return CartItemModel(
              product: prod, 
              quantity: (i['quantity'] as num?)?.toInt() ?? 1,
              selectedOptions: parsedOptions,
            );
          }).toList();
        } catch (e) {
          debugPrint('Fetch items for $trxId error: $e');
        }

        loaded.add(TransactionModel.fromMap(row, items: items));
      }

      _transactions = loaded;
    } catch (e) {
      debugPrint('Fetch transactions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simpan Transaksi Baru ke Supabase
  Future<bool> addTransaction(TransactionModel transaction) async {
    _transactions.insert(0, transaction); // Tampilkan langsung di UI
    notifyListeners();

    try {
      final supabase = SupabaseConfig.client;

      // 1. Insert header transaksi
      await supabase.from('transactions').insert(transaction.toMap());

      // 2. Insert items transaksi
      if (transaction.items.isNotEmpty) {
        final itemsData = transaction.items.map((item) {
          return {
            'transaction_id': transaction.id,
            'product_id': item.product.id,
            'product_name': item.product.name,
            'price': item.product.price,
            'cost_price': item.product.costPrice,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
            'selected_options': item.selectedOptions,
          };
        }).toList();

        await supabase.from('transaction_items').insert(itemsData);
      }

      return true;
    } catch (e) {
      debugPrint('Insert transaction to Supabase error: $e');
      return false;
    }
  }

  // ================= ANALITIK & LAPORAN =================

  // Total Omzet Hari Ini
  double get todayTotalRevenue {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.dateTime.year == now.year && t.dateTime.month == now.month && t.dateTime.day == now.day)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  // Total Transaksi Hari Ini
  int get todayTotalTransactions {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.dateTime.year == now.year && t.dateTime.month == now.month && t.dateTime.day == now.day)
        .length;
  }

  // Laba Kotor Hari Ini (Gross Profit = Revenue - HPP Modal)
  double get todayGrossProfit {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.dateTime.year == now.year && t.dateTime.month == now.month && t.dateTime.day == now.day)
        .fold(0.0, (sum, t) => sum + t.grossProfit);
  }

  // Total Omzet Bulan Ini
  double get thisMonthRevenue {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.dateTime.year == now.year && t.dateTime.month == now.month)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  // Total Laba Kotor Bulan Ini
  double get thisMonthGrossProfit {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.dateTime.year == now.year && t.dateTime.month == now.month)
        .fold(0.0, (sum, t) => sum + t.grossProfit);
  }

  // Top 5 Produk Terlaris
  List<Map<String, dynamic>> get topSellingProducts {
    final Map<String, int> qtyMap = {};
    final Map<String, double> revenueMap = {};

    for (var trx in _transactions) {
      for (var item in trx.items) {
        qtyMap[item.product.name] = (qtyMap[item.product.name] ?? 0) + item.quantity;
        revenueMap[item.product.name] = (revenueMap[item.product.name] ?? 0) + item.subtotal;
      }
    }

    final list = qtyMap.entries.map((e) {
      return {
        'name': e.key,
        'quantity': e.value,
        'revenue': revenueMap[e.key] ?? 0.0,
      };
    }).toList();

    list.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    return list.take(5).toList();
  }
}
