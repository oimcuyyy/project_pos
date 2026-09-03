import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/customer_model.dart';

class CustomerProvider with ChangeNotifier {
  List<CustomerModel> _customers = [];
  bool _isLoading = false;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;

  CustomerProvider() {
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final supabase = SupabaseConfig.client;
      final res = await supabase.from('customers').select().order('name');
      _customers = (res as List).map((c) => CustomerModel.fromMap(c)).toList();
    } catch (e) {
      debugPrint('Fetch customers error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCustomer(CustomerModel customer) async {
    try {
      final supabase = SupabaseConfig.client;
      final res = await supabase.from('customers').insert({
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'points': customer.points,
      }).select().single();
      
      _customers.add(CustomerModel.fromMap(res));
      _customers.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add customer error: $e');
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel customer) async {
    try {
      final supabase = SupabaseConfig.client;
      await supabase.from('customers').update({
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'points': customer.points,
      }).eq('id', customer.id);
      
      final idx = _customers.indexWhere((c) => c.id == customer.id);
      if (idx != -1) {
        _customers[idx] = customer;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Update customer error: $e');
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      final supabase = SupabaseConfig.client;
      await supabase.from('customers').delete().eq('id', id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete customer error: $e');
      return false;
    }
  }
}
