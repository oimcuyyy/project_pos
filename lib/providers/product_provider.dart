import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  List<String> _categories = ['All', 'Coffee', 'Non-Coffee', 'Pastry'];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get allProducts => _products;

  List<ProductModel> get products {
    if (_selectedCategory == 'All') return _products;
    return _products.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }

  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductProvider() {
    fetchProductsAndCategories();
  }

  void selectCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  // Ambil Data dari Supabase
  Future<void> fetchProductsAndCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.client;

      // 1. Fetch Categories
      try {
        final catRes = await supabase.from('categories').select('name').order('name');
        final fetchedCats = (catRes as List).map((c) => c['name'].toString()).toList();
        _categories = ['All', ...fetchedCats];
      } catch (e) {
        debugPrint('Fetch categories error: $e');
      }

      // 2. Fetch Products
      final prodRes = await supabase.from('products').select().order('name');
      final list = (prodRes as List).map((p) => ProductModel.fromMap(p)).toList();

      _products = list;
    } catch (e) {
      debugPrint('Fetch products error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tambah Produk Baru
  Future<bool> addProduct(ProductModel product) async {
    try {
      final supabase = SupabaseConfig.client;
      await supabase.from('products').insert(product.toMap());
      _products.add(product);
      
      // Auto tambahkan kategori jika belum ada di list
      if (!_categories.contains(product.category)) {
        await addCategory(product.category);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add product error: $e');
      return false;
    }
  }

  // Update Produk
  Future<bool> updateProduct(ProductModel product) async {
    try {
      final supabase = SupabaseConfig.client;
      await supabase.from('products').update(product.toMap()).eq('id', product.id);

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Update product error: $e');
      return false;
    }
  }

  // Hapus Produk
  Future<bool> deleteProduct(String productId) async {
    try {
      final supabase = SupabaseConfig.client;
      await supabase.from('products').delete().eq('id', productId);

      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete product error: $e');
      return false;
    }
  }

  // Tambah Kategori Baru
  Future<bool> addCategory(String categoryName) async {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty || _categories.contains(trimmed)) return false;

    try {
      final supabase = SupabaseConfig.client;
      await supabase.from('categories').insert({'name': trimmed});
      _categories.add(trimmed);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add category error: $e');
      _categories.add(trimmed); // fallback lokal
      notifyListeners();
      return true;
    }
  }

  // Tambah Stok (Restock)
  Future<void> addStock(String productId, int quantity) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final newStock = _products[index].stock + quantity;
      _products[index].stock = newStock;
      notifyListeners();

      try {
        final supabase = SupabaseConfig.client;
        await supabase.from('products').update({'stock': newStock}).eq('id', productId);
      } catch (e) {
        debugPrint('Update stock in DB error: $e');
      }
    }
  }

  // Kurangi Stok saat Checkout
  Future<void> reduceStock(String productId, int quantity) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final newStock = (_products[index].stock - quantity).clamp(0, 999999);
      _products[index].stock = newStock;
      notifyListeners();

      try {
        final supabase = SupabaseConfig.client;
        await supabase.from('products').update({'stock': newStock}).eq('id', productId);
      } catch (e) {
        debugPrint('Reduce stock in DB error: $e');
      }
    }
  }
}
