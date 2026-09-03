import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class EmployeeProvider with ChangeNotifier {
  List<UserModel> _employees = [];
  bool _isLoading = false;

  List<UserModel> get employees => _employees;
  bool get isLoading => _isLoading;

  EmployeeProvider() {
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    _isLoading = true;
    notifyListeners();
    try {
      final supabase = SupabaseConfig.client;
      final res = await supabase.from('users').select().order('name');
      _employees = (res as List).map((u) => UserModel.fromMap(u)).toList();
    } catch (e) {
      debugPrint('Fetch employees error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEmployee(String name, String username, String password, String role) async {
    try {
      final supabase = SupabaseConfig.client;
      final res = await supabase.from('users').insert({
        'name': name,
        'username': username,
        'password': password,
        'role': role,
      }).select().single();
      
      _employees.add(UserModel.fromMap(res));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add employee error: $e');
      return false;
    }
  }

  Future<bool> updateEmployee(String id, String name, String username, String? newPassword, String role) async {
    try {
      final supabase = SupabaseConfig.client;
      final Map<String, dynamic> updateData = {
        'name': name,
        'username': username,
        'role': role,
      };
      if (newPassword != null && newPassword.isNotEmpty) {
        updateData['password'] = newPassword;
      }

      await supabase.from('users').update(updateData).eq('id', id);
      
      final idx = _employees.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _employees[idx] = UserModel(id: id, name: name, username: username, role: role == 'admin' ? UserRole.admin : UserRole.cashier);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Update employee error: $e');
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      final supabase = SupabaseConfig.client;
      await supabase.from('users').delete().eq('id', id);
      _employees.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete employee error: $e');
      return false;
    }
  }
}
