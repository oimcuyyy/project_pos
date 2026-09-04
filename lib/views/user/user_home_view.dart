import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/login_view.dart';
import '../pos/widgets/magic_design_spells.dart';
import 'user_payment_view.dart' as user_payment_view;

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  Key _payButtonKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProductsAndCategories();
    });
  }

  void _showCheckoutSuccess() {
    // Kosongkan keranjang dan tampilkan notifikasi sukses
    context.read<CartProvider>().clearCart();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text('Pesanan Berhasil! 🎉', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Pesanan Anda sedang kami siapkan.\nSilakan tunggu sebentar ya.', 
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kembali ke Menu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = context.watch<ProductProvider>();
    final cartProv = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Menu Kami', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: prodProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kategori Filter (Bisa ditambahkan jika perlu, sementara tampilkan teks)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: const Text(
                    "Pilih makanan & minuman favorit Anda di bawah ini.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 250,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.75, // Proporsi kartu produk
                    ),
                    itemCount: prodProv.products.length,
                    itemBuilder: (context, index) {
                      final product = prodProv.products[index];
                      return MagicProductCard(
                        title: product.name,
                        price: _currency.format(product.price),
                        imageUrl: product.imageUrl,
                        onTap: () {
                          cartProv.addItem(product);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('${product.name} ditambahkan!')),
                                ],
                              ),
                              backgroundColor: Colors.green.shade700,
                              duration: const Duration(milliseconds: 1500),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cartProv.totalItemCount > 0
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cartProv.totalItemCount} Item di Keranjang',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        Text(
                          _currency.format(cartProv.totalPrice),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    MagicHoldToPayButton(
                      key: _payButtonKey,
                      label: "Tahan untuk Pesan & Bayar",
                      onCompleted: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const user_payment_view.UserPaymentView()),
                        );
                        if (result == true) {
                          _showCheckoutSuccess();
                        } else {
                          setState(() {
                            _payButtonKey = UniqueKey(); // Reset button if user cancels
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
