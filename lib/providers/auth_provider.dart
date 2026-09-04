import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../core/security/secure_storage_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final savedUserId = await SecureStorageService.getUserId();
      if (savedUserId != null) {
        final res = await SupabaseConfig.client
            .from('users')
            .select()
            .eq('id', savedUserId)
            .maybeSingle();
        if (res != null) {
          _currentUser = UserModel.fromMap(res);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to load session: $e');
    }
  }

  Future<String> _getUniqueDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      return webInfo.vendor ?? 'web_device';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; 
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macInfo = await deviceInfo.macOsInfo;
      return macInfo.systemGUID ?? 'mac_device';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.machineId ?? 'linux_device';
    }
    return 'unsupported_device';
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.client;
      final deviceId = await _getUniqueDeviceId();

      // Cek kredensial
      final res = await supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password) // In a real app, use hashed passwords
          .maybeSingle();

      if (res != null) {
        // Implementasi Device Binding Logic di Client-Side (sebaiknya di RPC Server)
        final boundDeviceId = res['bound_device_id']?.toString();
        
        if (boundDeviceId == null || boundDeviceId.isEmpty) {
          // Binding pertama kali
          await supabase.from('users').update({'bound_device_id': deviceId}).eq('id', res['id']);
        } else if (boundDeviceId != deviceId) {
          _errorMessage = "Akun ini telah terikat dengan perangkat lain!";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _currentUser = UserModel.fromMap(res);
        await SecureStorageService.saveUserId(_currentUser!.id);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Username atau password salah";
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _errorMessage = "Gagal login. Periksa koneksi internet.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await SecureStorageService.clearUserSession();
    notifyListeners();
  }
}

