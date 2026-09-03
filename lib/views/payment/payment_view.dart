import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/supabase_config.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/qris_helper.dart';
import 'receipt_view.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _cashController = TextEditingController();
  double _cashReceived = 0;
  bool _isProcessing = false;
  XFile? _proofImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        setState(() {
          _proofImage = picked;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _finishTransaction(PaymentMethod method) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final cart = context.read<CartProvider>();
    final productProv = context.read<ProductProvider>();
    final auth = context.read<AuthProvider>();
    final shiftProv = context.read<ShiftProvider>();
    final trxProv = context.read<TransactionProvider>();

    final total = cart.grandTotal;
    final change = _cashReceived >= total ? _cashReceived - total : 0.0;

    String? proofUrl;
    if (_proofImage != null) {
      try {
        final bytes = await _proofImage!.readAsBytes();
        final ext = _proofImage!.name.split('.').last;
        final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.$ext';
        
        await SupabaseConfig.client.storage
            .from('payment_proofs')
            .uploadBinary(fileName, bytes);
            
        proofUrl = SupabaseConfig.client.storage
            .from('payment_proofs')
            .getPublicUrl(fileName);
      } catch (e) {
        debugPrint('Error uploading proof: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Catatan bukti bayar: $e')));
        }
      }
    }

    final tx = TransactionModel(
      id: "TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
      dateTime: DateTime.now(),
      items: List.from(cart.itemList),
      subtotal: cart.subtotal,
      discount: cart.discountValue,
      tax: cart.taxValue,
      serviceCharge: cart.serviceChargeValue,
      totalAmount: total,
      paymentMethod: method,
      cashReceived: method == PaymentMethod.cash ? _cashReceived : total,
      change: method == PaymentMethod.cash ? change : 0,
      cashierName: auth.currentUser?.name ?? "Kasir",
      orderType: cart.orderType,
      tableNumber: cart.tableNumber,
      customerName: cart.customerName,
      customerPhone: cart.customerPhone,
      paymentProofUrl: proofUrl,
    );

    // 1. Kurangi stok produk
    for (var item in cart.itemList) {
      await productProv.reduceStock(item.product.id, item.quantity);
    }

    // 2. Catat penjualan ke shift kasir jika shift sedang aktif
    await shiftProv.addSale(total, method == PaymentMethod.cash);

    // 3. Simpan transaksi ke Supabase & list lokal
    await trxProv.addTransaction(tx);

    // 4. Kosongkan keranjang
    cart.clearCart();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // 5. Buka Halaman Cetak Struk
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ReceiptView(transaction: tx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final total = cart.grandTotal;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menyimpan Transaksi...', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.orderType} ${cart.tableNumber != null ? "• Meja ${cart.tableNumber}" : ""}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                          const Text('Tagihan Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        currency.format(total),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Tunai', icon: Icon(Icons.payments_outlined)),
                    Tab(text: 'Transfer', icon: Icon(Icons.account_balance_outlined)),
                    Tab(text: 'QRIS', icon: Icon(Icons.qr_code_2)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Tunai Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _cashController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Uang Tunai Diterima',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _cashReceived = double.tryParse(val) ?? 0;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [total, 50000, 100000, 200000].map((nominal) {
                                return ActionChip(
                                  label: Text(nominal == total ? 'Uang Pas' : currency.format(nominal)),
                                  onPressed: () {
                                    _cashController.text = nominal.toInt().toString();
                                    setState(() => _cashReceived = nominal.toDouble());
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Kembalian:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    currency.format(_cashReceived >= total ? _cashReceived - total : 0),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _cashReceived >= total ? () => _finishTransaction(PaymentMethod.cash) : null,
                              child: const Text('Bayar Tunai & Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),

                      // 2. Transfer Bank Tab
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Card(
                              child: ListTile(
                                leading: Icon(Icons.account_balance, color: Color(0xFF4F46E5)),
                                title: Text('BCA Virtual Account', style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('8801 2938 1029 4812 (a.n. Kopi Nusantara)'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Bukti Transfer / Screenshot', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickImage,
                              child: Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                ),
                                child: _proofImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: kIsWeb 
                                          ? Image.network(_proofImage!.path, fit: BoxFit.cover)
                                          : Image.file(File(_proofImage!.path), fit: BoxFit.cover),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Upload Bukti Bayar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                              ),
                            ),
                            const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: () => _finishTransaction(PaymentMethod.transfer),
                                  child: const Text('Konfirmasi Transfer Lunas', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              )
                          ],
                        ),
                      ),

                      // 3. QRIS Dinamis Tab
                      Builder(
                        builder: (context) {
                          final settings = context.watch<SettingsProvider>().settings;
                          final baseStaticQris = settings.qrisString.isNotEmpty
                              ? settings.qrisString
                              : QrisHelper.defaultStaticQris;
                          final dynamicQris = QrisHelper.convertToDynamic(
                            baseStaticQris,
                            total,
                          );
                          final qrisInfo = QrisHelper.parseQrisInfo(dynamicQris);

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.qr_code_scanner_rounded, color: Theme.of(context).colorScheme.primary),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'QRIS DINAMIS',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${qrisInfo['merchant_name']} • NMID: ${qrisInfo['nmid']}',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                        ),
                                        Text(
                                          '${qrisInfo['city']} (${qrisInfo['postal_code']})',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                        const Divider(height: 20),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: QrImageView(
                                            data: dynamicQris,
                                            version: QrVersions.auto,
                                            size: 200.0,
                                            backgroundColor: Colors.white,
                                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Total Tagihan: ${currency.format(total)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Nominal otomatis terisi di aplikasi pelanggan',
                                                style: TextStyle(fontSize: 10, color: Colors.black54),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: dynamicQris));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Payload QRIS Dinamis berhasil disalin ke clipboard'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.copy, size: 16),
                                          label: const Text('Salin String QRIS', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Scan melalui GoPay, OVO, DANA, ShopeePay, BCA, BRI, dll.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                const Text('Screenshot Bukti Bayar Pelanggan', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                    ),
                                    child: _proofImage != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: kIsWeb 
                                              ? Image.network(_proofImage!.path, fit: BoxFit.cover)
                                              : Image.file(File(_proofImage!.path), fit: BoxFit.cover),
                                          )
                                        : const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                                              SizedBox(height: 8),
                                              Text('Upload Bukti Bayar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Konfirmasi QRIS Berhasil & Cetak', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: () => _finishTransaction(PaymentMethod.qris),
                                    ),
                                  )
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
