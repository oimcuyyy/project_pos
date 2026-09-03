import 'dart:convert';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final double costPrice;
  final String category;
  int stock;
  final String? imageUrl;
  final String? description;
  final String? barcode;
  final List<dynamic> options;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.costPrice = 0,
    required this.category,
    required this.stock,
    this.imageUrl,
    this.description,
    this.barcode,
    this.options = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'category': category,
      'stock': stock,
      'image_url': imageUrl,
      'description': description,
      'barcode': barcode,
      'options': options,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    List<dynamic> parsedOptions = [];
    if (map['options'] != null) {
      if (map['options'] is String) {
        parsedOptions = jsonDecode(map['options']);
      } else if (map['options'] is List) {
        parsedOptions = map['options'];
      }
    }

    return ProductModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      category: map['category']?.toString() ?? 'Uncategorized',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url']?.toString(),
      description: map['description']?.toString(),
      barcode: map['barcode']?.toString(),
      options: parsedOptions,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    double? costPrice,
    String? category,
    int? stock,
    String? imageUrl,
    String? description,
    String? barcode,
    List<dynamic>? options,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      options: options ?? this.options,
    );
  }
}
