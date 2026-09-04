import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../core/security/secure_storage_service.dart';
import '../models/store_settings_model.dart';

class SettingsProvider with ChangeNotifier {
  StoreSettingsModel _settings = StoreSettingsModel();
  bool _isLoading = false;
  Timer? _pollingTimer;

  StoreSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _initSettings();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }


  Future<void> _initSettings() async {
    // 1. Muat status maintenance dari SecureStorage terlebih dahulu agar tidak reset saat app dibuka/rebuild
    try {
      final localMaint = await SecureStorageService.getMaintenanceMode();
      if (localMaint['is_maintenance'] == true) {
        _settings = _settings.copyWith(
          isMaintenance: true,
          maintenanceAdminName: localMaint['maintenance_admin_name'],
          maintenanceStartedAt: localMaint['maintenance_started_at'],
          maintenanceMessage: localMaint['maintenance_message'],
        );
        notifyListeners();
      }
    } catch (_) {}

    // 2. Fetch remote settings dari Supabase
    await fetchSettings();

    // 3. Polling tiap 10 detik agar kasir yang sudah login langsung terkunci jika admin menyalakan maintenance
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchSettings(silent: true);
    });
  }

  Future<void> fetchSettings({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final supabase = SupabaseConfig.client;
      final res = await supabase.from('store_settings').select().eq('id', 1).maybeSingle();
      if (res != null) {
        final remote = StoreSettingsModel.fromMap(res);
        final localMaint = await SecureStorageService.getMaintenanceMode();
        final localIsMaintenance = localMaint['is_maintenance'] == true;

        // PENTING: Mode maintenance HANYA boleh mati jika Admin secara manual menekan tombol OFF.
        // Jangan pernah ditimpa jadi false otomatis hanya karena login atau fetch remote data.
        final effectiveIsMaintenance = localIsMaintenance || remote.isMaintenance;

        _settings = remote.copyWith(
          isMaintenance: effectiveIsMaintenance,
          maintenanceAdminName: effectiveIsMaintenance
              ? (localIsMaintenance && (localMaint['maintenance_admin_name'] as String).isNotEmpty
                  ? localMaint['maintenance_admin_name']
                  : remote.maintenanceAdminName)
              : '',
          maintenanceStartedAt: effectiveIsMaintenance
              ? (localIsMaintenance && localMaint['maintenance_started_at'] != null
                  ? localMaint['maintenance_started_at']
                  : remote.maintenanceStartedAt)
              : null,
          maintenanceMessage: effectiveIsMaintenance
              ? (localIsMaintenance && (localMaint['maintenance_message'] as String).isNotEmpty
                  ? localMaint['maintenance_message']
                  : remote.maintenanceMessage)
              : remote.maintenanceMessage,
        );
      }
    } catch (e) {
      debugPrint('Fetch store settings error: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> updateSettings(StoreSettingsModel newSettings) async {
    _settings = newSettings;
    notifyListeners();

    // Selalu sinkronkan maintenance ke secure storage lokal
    await SecureStorageService.saveMaintenanceMode(
      isMaintenance: newSettings.isMaintenance,
      adminName: newSettings.maintenanceAdminName,
      startedAt: newSettings.maintenanceStartedAt,
      message: newSettings.maintenanceMessage,
    );

    try {
      final supabase = SupabaseConfig.client;
      await supabase.from('store_settings').upsert(newSettings.toMap());
      return true;
    } catch (e) {
      debugPrint('Update store settings full error: $e');
      // Fallback: jika kolom maintenance belum ada di remote DB Supabase, simpan setting inti
      try {
        final coreMap = {
          'id': newSettings.id,
          'store_name': newSettings.storeName,
          'address': newSettings.address,
          'phone': newSettings.phone,
          'footer_message': newSettings.footerMessage,
          'tax_percent': newSettings.taxPercent,
          'service_charge_percent': newSettings.serviceChargePercent,
          'qris_string': newSettings.qrisString,
          'use_kode_unik': newSettings.useKodeUnik,
          'qris_fee_percent': newSettings.qrisFeePercent,
        };
        await SupabaseConfig.client.from('store_settings').upsert(coreMap);
      } catch (_) {}
      return false;
    }
  }

  Future<bool> setMaintenanceMode(
    bool enabled, {
    String adminName = 'Admin',
    String message = 'Sistem kasir dan transaksi sedang dibekukan sementara untuk pemeliharaan keamanan atau audit darurat.',
  }) async {
    final updated = _settings.copyWith(
      isMaintenance: enabled,
      maintenanceAdminName: enabled ? adminName : '',
      maintenanceStartedAt: enabled ? DateTime.now() : null,
      maintenanceMessage: message,
    );

    // Langsung persist ke storage lokal agar tidak pernah mati otomatis saat login/rebuild
    await SecureStorageService.saveMaintenanceMode(
      isMaintenance: enabled,
      adminName: enabled ? adminName : '',
      startedAt: enabled ? updated.maintenanceStartedAt : null,
      message: message,
    );

    _settings = updated;
    notifyListeners();

    return await updateSettings(updated);
  }
}
