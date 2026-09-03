import 'package:flutter_test/flutter_test.dart';
import 'package:project_pos/utils/qris_helper.dart';

void main() {
  group('QrisHelper Tests', () {
    const staticQris = QrisHelper.defaultStaticQris;

    test('Validates default static QRIS CRC', () {
      expect(QrisHelper.validateCrc(staticQris), isTrue);
    });

    test('Converts static QRIS to dynamic QRIS with valid CRC', () {
      final amounts = [5000, 25000, 150000, 1250500];

      for (var amount in amounts) {
        final dynamicQris = QrisHelper.convertToDynamic(staticQris, amount);

        // Harus menggunakan indikator dynamic 010212
        expect(dynamicQris.contains('010212'), isTrue);

        // Harus memiliki tag 54 dengan amount
        final amtStr = amount.toString();
        final expectedTag54 = '54${amtStr.length.toString().padLeft(2, '0')}$amtStr';
        expect(dynamicQris.contains(expectedTag54), isTrue);

        // CRC harus valid
        expect(QrisHelper.validateCrc(dynamicQris), isTrue,
            reason: 'Failed CRC validation for amount: $amount, QR: $dynamicQris');
      }
    });

    test('Parses QRIS information correctly', () {
      final info = QrisHelper.parseQrisInfo(staticQris);
      expect(info['merchant_name'], 'Imzzzstore');
      expect(info['nmid'], 'ID1026500580471');
      expect(info['postal_code'], '12270');
    });
  });
}
