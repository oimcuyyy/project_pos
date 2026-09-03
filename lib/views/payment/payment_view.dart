import 'dart:convert';
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
  bool _isTransferVerified = false;
  bool _isQrisVerified = false;
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

  Future<void> _selectImageSource() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Bukti Transfer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Wajib dilampirkan agar kasir dapat memverifikasi kesesuaian pembayaran pelanggan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF4F46E5)),
                ),
                title: const Text('Ambil Foto Kamera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Foto langsung struk atau layar m-banking pelanggan', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(bCtx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Pilih dari Galeri / File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Unggah screenshot atau file foto bukti bayar', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(bCtx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        setState(() {
          _proofImage = picked;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  void _showProofPreviewDialog(BuildContext context) {
    if (_proofImage == null) return;
    showDialog(
      context: context,
      builder: (dCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFF1E293B),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pemeriksaan Bukti Transfer',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(dCtx),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: kIsWeb
                          ? Image.network(_proofImage!.path, fit: BoxFit.contain)
                          : Image.file(File(_proofImage!.path), fit: BoxFit.contain),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  color: const Color(0xFF1E293B),
                  child: Row(
                    children: [
                      const Icon(Icons.pinch_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Periksa nominal uang, nama pengirim, dan tanggal transfer.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          setState(() {
                            _isTransferVerified = true;
                            _isQrisVerified = true;
                          });
                          Navigator.pop(dCtx);
                        },
                        child: const Text('Sudah Sesuai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProofUploadSection(double total, String formattedTotal, {required bool isTransfer}) {
    final isVerified = isTransfer ? _isTransferVerified : _isQrisVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Color(0xFF4F46E5), size: 18),
            const SizedBox(width: 8),
            const Text(
              'Bukti Pembayaran / Transfer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                'WAJIB DIISI',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Wajib lampirkan foto struk/m-banking untuk verifikasi nominal ($formattedTotal) sebelum pesanan diproses.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        if (_proofImage == null) ...[
          // Belum Upload Bukti
          InkWell(
            onTap: _selectImageSource,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // Amber-50
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_a_photo_rounded, size: 30, color: Colors.amber.shade900),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ambil Foto Struk atau Upload Bukti Transfer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Klik di sini untuk memilih Kamera atau Galeri / File',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSourceChip(Icons.camera_alt_rounded, 'Foto Kamera Langsung'),
                      const SizedBox(width: 8),
                      _buildSourceChip(Icons.photo_library_rounded, 'Pilih Galeri / File'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tombol konfirmasi transaksi terkunci sampai bukti transfer dilampirkan.',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Sudah Upload Bukti - Preview Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image Thumbnail with Zoom Prompt
                    GestureDetector(
                      onTap: () => _showProofPreviewDialog(context),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: kIsWeb
                                  ? Image.network(_proofImage!.path, fit: BoxFit.cover)
                                  : Image.file(File(_proofImage!.path), fit: BoxFit.cover),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
                            ),
                            child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details & Actions
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'BUKTI TERLAMPIR',
                                  style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _proofImage!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                                  foregroundColor: const Color(0xFF4F46E5),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.fullscreen_rounded, size: 16),
                                label: const Text('Periksa Bukti', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () => _showProofPreviewDialog(context),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 14),
                                label: const Text('Ganti', style: TextStyle(fontSize: 11)),
                                onPressed: _selectImageSource,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                tooltip: 'Hapus bukti',
                                onPressed: () => setState(() {
                                  _proofImage = null;
                                  if (isTransfer) {
                                    _isTransferVerified = false;
                                  } else {
                                    _isQrisVerified = false;
                                  }
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // CHECKBOX KONFIRMASI KASIR
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      if (isTransfer) {
                        _isTransferVerified = !_isTransferVerified;
                      } else {
                        _isQrisVerified = !_isQrisVerified;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isVerified ? Colors.green.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isVerified ? Colors.green.shade400 : const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isVerified,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) {
                            setState(() {
                              if (isTransfer) {
                                _isTransferVerified = val ?? false;
                              } else {
                                _isQrisVerified = val ?? false;
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Saya (Kasir) telah memeriksa bukti dan memastikan transfer $formattedTotal sudah masuk ke rekening toko.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isVerified ? FontWeight.bold : FontWeight.w500,
                              color: isVerified ? Colors.green.shade900 : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Future<void> _finishTransaction(PaymentMethod method) async {
    if (_isProcessing) return;

    // VALIDASI KETAT WAJIB BUKTI TRANSFER & KONFIRMASI KASIR
    if (method == PaymentMethod.transfer || method == PaymentMethod.qris) {
      if (_proofImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Wajib melampirkan foto bukti transfer untuk metode ${method == PaymentMethod.qris ? "QRIS" : "Transfer Bank"}!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _selectImageSource();
        return;
      }

      final isVerified = method == PaymentMethod.transfer ? _isTransferVerified : _isQrisVerified;
      if (!isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_box_outline_blank_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Harap centang konfirmasi verifikasi bukti transfer terlebih dahulu!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

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
        
        try {
          await SupabaseConfig.client.storage
              .from('payment_proofs')
              .uploadBinary(fileName, bytes);
              
          proofUrl = SupabaseConfig.client.storage
              .from('payment_proofs')
              .getPublicUrl(fileName);
        } catch (uploadErr) {
          debugPrint('Upload to Supabase storage error: $uploadErr');
          // Fallback: simpan sebagai data URI Base64 agar bukti TIDAK PERNAH HILANG
          final base64String = base64Encode(bytes);
          proofUrl = 'data:image/$ext;base64,$base64String';
        }
      } catch (e) {
        debugPrint('Error reading proof bytes: $e');
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
                  Text('Memproses transaksi & menyimpan bukti...', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Total Banner
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    child: Column(
                      children: [
                        const Text('Total Tagihan', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(total),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Pilihan
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(icon: Icon(Icons.money), text: 'Tunai'),
                      Tab(icon: Icon(Icons.account_balance), text: 'Transfer'),
                      Tab(icon: Icon(Icons.qr_code_2), text: 'QRIS'),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // 1. Tunai Tab
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _cashController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  labelText: 'Uang Diterima',
                                  prefixText: 'Rp ',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _cashReceived = double.tryParse(val) ?? 0;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              // Shortcut uang pas & pecahan umum
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    label: const Text('Uang Pas'),
                                    onPressed: () {
                                      setState(() {
                                        _cashReceived = total;
                                        _cashController.text = total.toInt().toString();
                                      });
                                    },
                                  ),
                                  ...[10000, 20000, 50000, 100000].map((nominal) {
                                    if (nominal >= total) {
                                      return ActionChip(
                                        label: Text(currency.format(nominal)),
                                        onPressed: () {
                                          setState(() {
                                            _cashReceived = nominal.toDouble();
                                            _cashController.text = nominal.toString();
                                          });
                                        },
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Kembalian:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    Text(
                                      currency.format(_cashReceived >= total ? _cashReceived - total : 0),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _cashReceived >= total ? () => _finishTransaction(PaymentMethod.cash) : null,
                                  child: const Text('Bayar Tunai & Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Transfer Bank Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Card(
                                child: ListTile(
                                  leading: Icon(Icons.account_balance, color: Color(0xFF4F46E5)),
                                  title: Text('BCA Virtual Account', style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('8801 2938 1029 4812 (a.n. Kopi Nusantara)'),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // BUKTI TRANSFER SECTION (WAJIB)
                              _buildProofUploadSection(total, currency.format(total), isTransfer: true),

                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: (_proofImage != null && _isTransferVerified)
                                        ? const Color(0xFF10B981)
                                        : Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: Icon(
                                    (_proofImage != null && _isTransferVerified)
                                        ? Icons.check_circle_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 20,
                                  ),
                                  label: Text(
                                    _proofImage == null
                                        ? 'Terkunci (Wajib Upload Bukti Transfer)'
                                        : (!_isTransferVerified
                                            ? 'Centang Verifikasi Bukti Terlebih Dahulu'
                                            : 'Konfirmasi Transfer Lunas & Cetak'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: (_proofImage != null && _isTransferVerified)
                                      ? () => _finishTransaction(PaymentMethod.transfer)
                                      : null, // BENAR-BENAR TERKUNCI & TIDAK BISA DIKLIK!
                                ),
                              ),
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  const SizedBox(height: 20),

                                  // BUKTI TRANSFER QRIS SECTION (WAJIB)
                                  _buildProofUploadSection(total, currency.format(total), isTransfer: false),

                                  const SizedBox(height: 28),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: (_proofImage != null && _isQrisVerified)
                                            ? const Color(0xFF10B981)
                                            : Colors.grey.shade400,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: Icon(
                                        (_proofImage != null && _isQrisVerified)
                                            ? Icons.check_circle_rounded
                                            : Icons.lock_outline_rounded,
                                        size: 20,
                                      ),
                                      label: Text(
                                        _proofImage == null
                                            ? 'Terkunci (Wajib Upload Bukti QRIS)'
                                            : (!_isQrisVerified
                                                ? 'Centang Verifikasi Bukti Terlebih Dahulu'
                                                : 'Konfirmasi QRIS Berhasil & Cetak'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      onPressed: (_proofImage != null && _isQrisVerified)
                                          ? () => _finishTransaction(PaymentMethod.qris)
                                          : null, // BENAR-BENAR TERKUNCI & TIDAK BISA DIKLIK!
                                    ),
                                  ),
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
    );
  }
}
