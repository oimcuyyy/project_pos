/// Utility helper untuk konversi QRIS Statis ke QRIS Dinamis
/// Berdasarkan implementasi engine 3QRIS (CRC16-CCITT / EMVCo Standard)
class QrisHelper {
  /// Default QRIS Statis dari file QRIS.jpeg
  static const String defaultStaticQris =
      '00020101021126570011ID.DANA.WWW011893600915301409631402090140963140303UMI51440014ID.CO.QRIS.WWW0215ID10265005804710303UMI5204594553033605802ID5910Imzzzstore6015Kota Jakarta Se6105122706304F45D';

  /// Menghitung CRC16 (CCITT-FALSE, Poly: 0x1021, Init: 0xFFFF)
  static String crc16(String str) {
    int crc = 0xFFFF;
    for (int i = 0; i < str.length; i++) {
      crc ^= str.codeUnitAt(i) << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Memvalidasi checksum CRC16 pada string QRIS
  static bool validateCrc(String qrisStr) {
    final clean = qrisStr.trim();
    if (clean.length < 8) return false;
    final expectedCrc = clean.substring(clean.length - 4);
    final body = clean.substring(0, clean.length - 4);
    return crc16(body) == expectedCrc.toUpperCase();
  }

  /// Parser TLV (Tag-Length-Value) sesuai standar EMVCo / QRIS
  static Map<String, String> parseTLV(String qris) {
    final tags = <String, String>{};
    int i = 0;
    while (i + 4 <= qris.length) {
      final tag = qris.substring(i, i + 2);
      final len = int.tryParse(qris.substring(i + 2, i + 4));
      if (len == null || len < 0) break;
      i += 4;
      if (i + len > qris.length) break;
      final value = qris.substring(i, i + len);
      tags[tag] = value;
      i += len;
    }
    return tags;
  }

  /// Mengonversi QRIS Statis menjadi QRIS Dinamis dengan nominal tagihan
  /// Sesuai algoritma engine 3QRIS
  /// [useDynamicTag] jika true mengubah tag 010211 -> 010212 (standar 3QRIS dinamis)
  static String convertToDynamic(
    String staticStr,
    num amount, {
    bool useDynamicTag = true,
  }) {
    final cleanStr = staticStr.trim();
    if (cleanStr.isEmpty) return '';

    // Ambil string sebelum tag 63 (CRC - 8 karakter terakhir: 6304XXXX)
    String body = cleanStr.length > 8 ? cleanStr.substring(0, cleanStr.length - 8) : cleanStr;

    // Ganti 010211 (Static QR) menjadi 010212 (Dynamic QR) jika useDynamicTag aktif
    if (useDynamicTag) {
      body = body.replaceAll('010211', '010212');
    }

    // Hapus Tag 54 (amount) lama jika sudah pernah ada
    body = body.replaceAll(RegExp(r'54\d{2}\d+(?=5[5-9]|6[0-9]|8[0-9])'), '');

    // Format nominal ke Tag 54 (54 + 2 digit panjang + nominal bulat)
    final amtStr = amount.toInt().toString();
    final tag54 = '54${amtStr.length.toString().padLeft(2, '0')}$amtStr';

    // Sisipkan Tag 54 sebelum Tag 58 (5802ID) atau di akhir string
    if (body.contains('5802ID')) {
      body = body.replaceFirst('5802ID', '$tag54' '5802ID');
    } else {
      body = body + tag54;
    }

    // Tambahkan header tag 63 untuk CRC: 6304
    final withCrcHeader = '$body' '6304';

    // Hitung dan tambahkan nilai CRC16 baru
    final crc = crc16(withCrcHeader);
    return '$withCrcHeader$crc';
  }

  /// Ekstrak informasi merchant dari payload QRIS (NMID, Nama Merchant, Kota, dll.)
  static Map<String, String> parseQrisInfo(String qrisStr) {
    final tags = parseTLV(qrisStr);
    final info = <String, String>{
      'merchant_name': tags['59'] ?? 'Imzzzstore',
      'nmid': 'ID1026500580471',
      'city': tags['60'] ?? 'Kota Jakarta Se',
      'postal_code': tags['61'] ?? '12270',
      'currency': tags['53'] == '360' ? 'IDR' : (tags['53'] ?? 'IDR'),
    };

    // Ekstrak NMID dari Tag 51 atau 26 jika ada sub-TLV
    if (tags.containsKey('51')) {
      final subTags51 = parseTLV(tags['51']!);
      if (subTags51.containsKey('02')) {
        info['nmid'] = subTags51['02']!;
      }
    } else if (tags.containsKey('26')) {
      final subTags26 = parseTLV(tags['26']!);
      if (subTags26.containsKey('02')) {
        info['nmid'] = subTags26['02']!;
      }
    }

    return info;
  }
}
