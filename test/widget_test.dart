import 'package:flutter_test/flutter_test.dart';
import 'package:project_pos/models/product_model.dart';
import 'package:project_pos/models/store_settings_model.dart';
import 'package:project_pos/providers/cart_provider.dart';
import 'package:project_pos/utils/qris_helper.dart';

void main() {
  test('QrisHelper generates valid dynamic QRIS', () {
    const staticQris = QrisHelper.defaultStaticQris;
    final dynamicQris = QrisHelper.convertToDynamic(staticQris, 50000);

    expect(dynamicQris, contains('010212'));
    expect(dynamicQris, contains('540550000'));
    expect(QrisHelper.validateCrc(dynamicQris), isTrue);
  });

  group('CartProvider & POS Flow Tests', () {
    late CartProvider cart;
    late ProductModel testProduct;

    setUp(() {
      cart = CartProvider();
      testProduct = ProductModel(
        id: 'P01',
        name: 'Kopi Susu Gula Aren',
        price: 20000,
        costPrice: 10000,
        category: 'Coffee',
        stock: 2,
        options: [
          {
            'name': 'Ukuran',
            'choices': [
              {'name': 'Regular', 'price': 0},
              {'name': 'Large', 'price': 5000},
            ]
          }
        ],
      );
    });

    test('addItem respects total product stock across different options', () {
      // Stock is 2
      cart.addItem(testProduct, options: [{'group': 'Ukuran', 'name': 'Regular', 'price': 0.0}]);
      expect(cart.totalItemCount, 1);

      cart.addItem(testProduct, options: [{'group': 'Ukuran', 'name': 'Large', 'price': 5000.0}]);
      expect(cart.totalItemCount, 2);

      // Attempt to add beyond product stock limit (2)
      cart.addItem(testProduct, options: [{'group': 'Ukuran', 'name': 'Regular', 'price': 0.0}]);
      expect(cart.totalItemCount, 2);
    });

    test('holdCurrentOrder preserves customer phone and resumes correctly', () {
      cart.setOrderType('Take Away');
      cart.setCustomerInfo('Budi Santoso', '08123456789');
      cart.addItem(testProduct);

      final held = cart.holdCurrentOrder('Antrean Budi');
      expect(held, isTrue);
      expect(cart.items.isEmpty, isTrue);
      expect(cart.heldOrders.length, 1);

      final heldOrder = cart.heldOrders.first;
      expect(heldOrder.customerName, 'Budi Santoso');
      expect(heldOrder.customerPhone, '08123456789');
      expect(heldOrder.orderType, 'Take Away');

      // Resume
      cart.resumeHeldOrder(heldOrder);
      expect(cart.customerName, 'Budi Santoso');
      expect(cart.customerPhone, '08123456789');
      expect(cart.orderType, 'Take Away');
      expect(cart.totalItemCount, 1);
      expect(cart.heldOrders.isEmpty, isTrue);
    });

    test('subtotal and grandTotal calculate correctly with discounts and taxes', () {
      cart.addItem(testProduct, options: [{'group': 'Ukuran', 'name': 'Large', 'price': 5000.0}]);
      // Price: 20000 + 5000 = 25000
      expect(cart.subtotal, 25000.0);

      // 10% discount
      cart.setDiscount(percent: 10);
      expect(cart.discountValue, 2500.0);
      expect(cart.afterDiscount, 22500.0);

      // 10% tax
      cart.setTaxAndService(tax: 10, service: 0);
      expect(cart.taxValue, 2250.0);
      expect(cart.grandTotal, 24750.0);
    });
  });

  group('StoreSettingsModel & Maintenance Mode Tests', () {
    test('Maintenance mode attributes serialize and deserialize correctly', () {
      final now = DateTime.now();
      final settings = StoreSettingsModel(
        storeName: 'Cafe Nusantara',
        isMaintenance: true,
        maintenanceAdminName: 'Admin Budi',
        maintenanceStartedAt: now,
        maintenanceMessage: 'Audit keamanan darurat dilakukan.',
      );

      final map = settings.toMap();
      expect(map['is_maintenance'], isTrue);
      expect(map['maintenance_admin_name'], 'Admin Budi');
      expect(map['maintenance_message'], 'Audit keamanan darurat dilakukan.');

      final parsed = StoreSettingsModel.fromMap(map);
      expect(parsed.isMaintenance, isTrue);
      expect(parsed.maintenanceAdminName, 'Admin Budi');
      expect(parsed.maintenanceMessage, 'Audit keamanan darurat dilakukan.');
      expect(parsed.maintenanceStartedAt?.second, now.second);
    });

    test('copyWith properly updates maintenance attributes', () {
      final initial = StoreSettingsModel();
      expect(initial.isMaintenance, isFalse);

      final locked = initial.copyWith(
        isMaintenance: true,
        maintenanceAdminName: 'Super Admin',
        maintenanceMessage: 'Kunci darurat karena terdeteksi fraud.',
      );

      expect(locked.isMaintenance, isTrue);
      expect(locked.maintenanceAdminName, 'Super Admin');
      expect(locked.maintenanceMessage, 'Kunci darurat karena terdeteksi fraud.');
    });
  });
}
