import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/printer_provider.dart';
import '../../providers/settings_provider.dart';
import '../pos/pos_home_view.dart';

class ReceiptView extends StatefulWidget {
  final TransactionModel transaction;
  const ReceiptView({super.key, required this.transaction});

  @override
  State<ReceiptView> createState() => _ReceiptViewState();
}

class _ReceiptViewState extends State<ReceiptView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final printer = context.read<PrinterProvider>();
      printer.initBluetooth();
      printer.scanDevices();
    });
  }

  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pilih Thermal Printer'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<PrinterProvider>(
            builder: (context, prov, _) {
              if (prov.devices.isEmpty) {
                return const Text('Tidak ada perangkat terpasang. Pasangkan printer di pengaturan Bluetooth HP terlebih dahulu.');
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: prov.devices.length,
                itemBuilder: (ctx, i) {
                  final d = prov.devices[i];
                  return ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(d.name ?? 'Device'),
                    subtitle: Text(d.address ?? ''),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      final connected = await prov.connect(d);
                      if (connected) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Terhubung ke ${d.name}')),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final printer = context.watch<PrinterProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final tx = widget.transaction;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                // Preview Virtual Struk Thermal (Animasi Paper Ejection)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) => Transform.translate(
                    offset: Offset(0, -30 * (1 - val)),
                    child: Opacity(
                      opacity: val.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(settings.storeName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(settings.address, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('Telp: ${settings.phone}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Divider(thickness: 1, height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tx.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(DateFormat('dd/MM/yy HH:mm').format(tx.dateTime), style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kasir: ${tx.cashierName}', style: const TextStyle(fontSize: 11)),
                      Text('${tx.orderType} ${tx.tableNumber != null ? "• Meja ${tx.tableNumber}" : ""}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (tx.customerName != null && tx.customerName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Text('Pelanggan: ${tx.customerName}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),

                  const Divider(thickness: 1, height: 20),

                  ...tx.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('${item.product.name} x${item.quantity}', style: const TextStyle(fontSize: 13)),
                                ),
                                Text(currency.format(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            if (item.selectedOptions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  item.selectedOptions.map((opt) {
                                    final optPrice = (opt['price'] as num?)?.toDouble() ?? 0.0;
                                    final priceStr = optPrice > 0 ? ' (+${currency.format(optPrice)})' : '';
                                    return '${opt['name']}$priceStr';
                                  }).join(', '),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      )),

                  const Divider(thickness: 1, height: 20),

                  if (tx.discount > 0 || tx.tax > 0 || tx.serviceCharge > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(currency.format(tx.subtotal), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    if (tx.discount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Diskon', style: TextStyle(fontSize: 12, color: Colors.green)),
                          Text('- ${currency.format(tx.discount)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                        ],
                      ),
                    if (tx.tax > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pajak PPN', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(currency.format(tx.tax), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    if (tx.serviceCharge > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Service Charge', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(currency.format(tx.serviceCharge), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    const SizedBox(height: 6),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(currency.format(tx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Metode Bayar:', style: TextStyle(fontSize: 12)),
                      Text(tx.paymentMethod.name.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (tx.paymentMethod == PaymentMethod.cash) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tunai:', style: TextStyle(fontSize: 12)),
                        Text(currency.format(tx.cashReceived), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian:', style: TextStyle(fontSize: 12)),
                        Text(currency.format(tx.change), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    settings.footerMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

            // Bluetooth Printer Control Status
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey.shade100,
              leading: Icon(
                Icons.print,
                color: printer.isConnected ? Colors.green : Colors.grey,
              ),
              title: Text(printer.isConnected
                  ? 'Printer: ${printer.selectedDevice?.name ?? "Connected"}'
                  : 'Belum Terhubung ke Printer'),
              trailing: OutlinedButton(
                onPressed: _showPrinterDialog,
                child: Text(printer.isConnected ? 'Ganti' : 'Pilih Printer'),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const PosHomeView()),
                        (route) => false,
                      );
                    },
                    child: const Text('Transaksi Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.print),
                    label: const Text('Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      if (!printer.isConnected) {
                        _showPrinterDialog();
                        return;
                      }
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await printer.printReceipt(
                        tx,
                        storeName: settings.storeName,
                        address: settings.address,
                        phone: settings.phone,
                        footerMessage: settings.footerMessage,
                      );
                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Struk berhasil dicetak!')),
                        );
                      }
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
