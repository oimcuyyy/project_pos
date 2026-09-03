import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction_model.dart';

class PrinterProvider with ChangeNotifier {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isScanning = false;

  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;

  Future<void> initBluetooth() async {
    // Request permission Bluetooth & Lokasi (Android 12+)
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    _bluetooth.onStateChanged().listen((state) {
      if (state == BlueThermalPrinter.DISCONNECTED) {
        _isConnected = false;
        notifyListeners();
      }
    });
  }

  Future<void> scanDevices() async {
    _isScanning = true;
    notifyListeners();
    try {
      _devices = await _bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint("Error get devices: $e");
    }
    _isScanning = false;
    notifyListeners();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _bluetooth.connect(device);
      _selectedDevice = device;
      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Connection failed: $e");
      return false;
    }
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _isConnected = false;
    _selectedDevice = null;
    notifyListeners();
  }

  /// Format & Kirim Data ke Thermal Printer 58mm
  Future<bool> printReceipt(
    TransactionModel tx, {
    String storeName = "Kopi Nusantara POS",
    String address = "Jl. Raya Kopi No. 12, Jakarta",
    String phone = "0812-3456-7890",
    String footerMessage = "Terima kasih atas kunjungan Anda!",
  }) async {
    final connected = await _bluetooth.isConnected;
    if (connected != true) {
      return false;
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(tx.dateTime);

    // ESC/POS Formatting: size (0=Normal, 1=Medium, 2=Large), align (0=Left, 1=Center, 2=Right)
    _bluetooth.printCustom(storeName, 2, 1);
    if (address.isNotEmpty) _bluetooth.printCustom(address, 0, 1);
    if (phone.isNotEmpty) _bluetooth.printCustom("Telp: $phone", 0, 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);

    _bluetooth.printLeftRight("No: ${tx.id}", "Kasir: ${tx.cashierName}", 0);
    _bluetooth.printCustom("Waktu: $dateStr", 0, 0);
    _bluetooth.printCustom("${tx.orderType}${tx.tableNumber != null ? ' - Meja ${tx.tableNumber}' : ''}", 0, 0);
    if (tx.customerName != null && tx.customerName!.isNotEmpty) {
      _bluetooth.printCustom("Pelanggan: ${tx.customerName}", 0, 0);
    }
    _bluetooth.printCustom("--------------------------------", 1, 1);

    // Detail Items
    for (var item in tx.items) {
      _bluetooth.printCustom(item.product.name, 0, 0);
      if (item.selectedOptions.isNotEmpty) {
        final optStr = item.selectedOptions.map((o) => o['name']).join(', ');
        _bluetooth.printCustom("  ($optStr)", 0, 0);
      }
      final unitPrice = item.subtotal / item.quantity;
      _bluetooth.printLeftRight(
        "  ${item.quantity} x ${currency.format(unitPrice)}",
        currency.format(item.subtotal),
        0,
      );
    }

    _bluetooth.printCustom("--------------------------------", 1, 1);
    if (tx.discount > 0 || tx.tax > 0 || tx.serviceCharge > 0) {
      _bluetooth.printLeftRight("Subtotal:", currency.format(tx.subtotal), 0);
      if (tx.discount > 0) {
        _bluetooth.printLeftRight("Diskon:", "-${currency.format(tx.discount)}", 0);
      }
      if (tx.tax > 0) {
        _bluetooth.printLeftRight("Pajak:", currency.format(tx.tax), 0);
      }
      if (tx.serviceCharge > 0) {
        _bluetooth.printLeftRight("Service:", currency.format(tx.serviceCharge), 0);
      }
    }
    _bluetooth.printLeftRight("TOTAL:", currency.format(tx.totalAmount), 1);
    _bluetooth.printLeftRight("Metode Bayar:", tx.paymentMethod.name.toUpperCase(), 0);

    if (tx.paymentMethod == PaymentMethod.cash) {
      _bluetooth.printLeftRight("Tunai:", currency.format(tx.cashReceived), 0);
      _bluetooth.printLeftRight("Kembali:", currency.format(tx.change), 0);
    }

    _bluetooth.printCustom("--------------------------------", 1, 1);
    if (footerMessage.isNotEmpty) {
      _bluetooth.printCustom(footerMessage, 0, 1);
    }
    _bluetooth.printCustom("Barang yg dibeli tdk dpt ditukar", 0, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();

    return true;
  }
}
