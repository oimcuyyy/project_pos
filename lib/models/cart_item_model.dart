import 'product_model.dart';
import 'dart:convert';

class CartItemModel {
  final ProductModel product;
  int quantity;
  final List<Map<String, dynamic>> selectedOptions;
  final String uniqueId;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedOptions = const [],
    String? uniqueId,
  }) : uniqueId = uniqueId ?? '${product.id}_${DateTime.now().millisecondsSinceEpoch}';

  double get subtotal {
    double basePrice = product.price;
    double optionsPrice = 0.0;
    
    for (var opt in selectedOptions) {
      if (opt.containsKey('price')) {
        optionsPrice += (opt['price'] as num).toDouble();
      }
    }
    
    return (basePrice + optionsPrice) * quantity;
  }

  // Helper to generate a deterministic ID based on product and selected options
  static String generateId(String productId, List<Map<String, dynamic>> options) {
    if (options.isEmpty) return productId;
    
    // Sort options to ensure consistent ID regardless of order
    final sortedOptions = List<Map<String, dynamic>>.from(options);
    sortedOptions.sort((a, b) => (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));
    
    final optionsStr = jsonEncode(sortedOptions);
    return '${productId}_$optionsStr';
  }
}
