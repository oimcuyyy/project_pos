import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  static Future<void> clearUserSession() async {
    await _storage.delete(key: 'user_id');
  }

  static Future<void> saveMaintenanceMode({
    required bool isMaintenance,
    required String adminName,
    DateTime? startedAt,
    required String message,
  }) async {
    try {
      await _storage.write(key: 'maintenance_is_active', value: isMaintenance ? 'true' : 'false');
      await _storage.write(key: 'maintenance_admin_name', value: adminName);
      if (startedAt != null) {
        await _storage.write(key: 'maintenance_started_at', value: startedAt.toIso8601String());
      } else {
        await _storage.delete(key: 'maintenance_started_at');
      }
      await _storage.write(key: 'maintenance_message', value: message);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getMaintenanceMode() async {
    try {
      final isActiveStr = await _storage.read(key: 'maintenance_is_active');
      final adminName = await _storage.read(key: 'maintenance_admin_name') ?? '';
      final startedAtStr = await _storage.read(key: 'maintenance_started_at');
      final message = await _storage.read(key: 'maintenance_message') ??
          'Sistem kasir dan transaksi sedang dibekukan sementara untuk pemeliharaan keamanan atau audit darurat.';

      return {
        'is_maintenance': isActiveStr == 'true',
        'maintenance_admin_name': adminName,
        'maintenance_started_at': startedAtStr != null ? DateTime.tryParse(startedAtStr) : null,
        'maintenance_message': message,
      };
    } catch (_) {
      return {
        'is_maintenance': false,
        'maintenance_admin_name': '',
        'maintenance_started_at': null,
        'maintenance_message': 'Sistem kasir dan transaksi sedang dibekukan sementara untuk pemeliharaan keamanan atau audit darurat.',
      };
    }
  }
}
