import '../utils/qris_helper.dart';

class StoreSettingsModel {
  final int id;
  final String storeName;
  final String address;
  final String phone;
  final String footerMessage;
  final double taxPercent;
  final double serviceChargePercent;
  final String qrisString;
  final bool useKodeUnik;
  final double qrisFeePercent;
  final bool isMaintenance;
  final String maintenanceAdminName;
  final DateTime? maintenanceStartedAt;
  final String maintenanceMessage;

  StoreSettingsModel({
    this.id = 1,
    this.storeName = 'Kopi Nusantara POS',
    this.address = 'Jl. Raya Kopi No. 12, Jakarta',
    this.phone = '0812-3456-7890',
    this.footerMessage = 'Terima kasih atas kunjungan Anda!',
    this.taxPercent = 0.0,
    this.serviceChargePercent = 0.0,
    this.qrisString = QrisHelper.defaultStaticQris,
    this.useKodeUnik = false,
    this.qrisFeePercent = 0.0,
    this.isMaintenance = false,
    this.maintenanceAdminName = '',
    this.maintenanceStartedAt,
    this.maintenanceMessage = 'Sistem kasir dan transaksi sedang dibekukan sementara untuk pemeliharaan keamanan atau audit darurat.',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_name': storeName,
      'address': address,
      'phone': phone,
      'footer_message': footerMessage,
      'tax_percent': taxPercent,
      'service_charge_percent': serviceChargePercent,
      'qris_string': qrisString,
      'use_kode_unik': useKodeUnik,
      'qris_fee_percent': qrisFeePercent,
      'is_maintenance': isMaintenance,
      'maintenance_admin_name': maintenanceAdminName,
      'maintenance_started_at': maintenanceStartedAt?.toIso8601String(),
      'maintenance_message': maintenanceMessage,
    };
  }

  factory StoreSettingsModel.fromMap(Map<String, dynamic> map) {
    return StoreSettingsModel(
      id: (map['id'] as num?)?.toInt() ?? 1,
      storeName: map['store_name']?.toString() ?? 'Kopi Nusantara POS',
      address: map['address']?.toString() ?? 'Jl. Raya Kopi No. 12, Jakarta',
      phone: map['phone']?.toString() ?? '0812-3456-7890',
      footerMessage: map['footer_message']?.toString() ?? 'Terima kasih atas kunjungan Anda!',
      taxPercent: (map['tax_percent'] as num?)?.toDouble() ?? 0.0,
      serviceChargePercent: (map['service_charge_percent'] as num?)?.toDouble() ?? 0.0,
      qrisString: map['qris_string']?.toString() ?? QrisHelper.defaultStaticQris,
      useKodeUnik: map['use_kode_unik'] == true,
      qrisFeePercent: (map['qris_fee_percent'] as num?)?.toDouble() ?? 0.0,
      isMaintenance: map['is_maintenance'] == true,
      maintenanceAdminName: map['maintenance_admin_name']?.toString() ?? '',
      maintenanceStartedAt: map['maintenance_started_at'] != null ? DateTime.tryParse(map['maintenance_started_at'].toString()) : null,
      maintenanceMessage: map['maintenance_message']?.toString() ?? 'Sistem kasir dan transaksi sedang dibekukan sementara untuk pemeliharaan keamanan atau audit darurat.',
    );
  }

  StoreSettingsModel copyWith({
    int? id,
    String? storeName,
    String? address,
    String? phone,
    String? footerMessage,
    double? taxPercent,
    double? serviceChargePercent,
    String? qrisString,
    bool? useKodeUnik,
    double? qrisFeePercent,
    bool? isMaintenance,
    String? maintenanceAdminName,
    DateTime? maintenanceStartedAt,
    String? maintenanceMessage,
  }) {
    return StoreSettingsModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      footerMessage: footerMessage ?? this.footerMessage,
      taxPercent: taxPercent ?? this.taxPercent,
      serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
      qrisString: qrisString ?? this.qrisString,
      useKodeUnik: useKodeUnik ?? this.useKodeUnik,
      qrisFeePercent: qrisFeePercent ?? this.qrisFeePercent,
      isMaintenance: isMaintenance ?? this.isMaintenance,
      maintenanceAdminName: maintenanceAdminName ?? this.maintenanceAdminName,
      maintenanceStartedAt: maintenanceStartedAt ?? this.maintenanceStartedAt,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
    );
  }
}
