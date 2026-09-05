import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/login_view.dart';
import '../pos/widgets/magic_design_spells.dart';
import 'user_payment_view.dart' as user_payment_view;
import '../../models/product_model.dart';

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

  void _showOptionsDialog(BuildContext context, ProductModel product, CartProvider cartProv) {
    Map<String, dynamic> selectedOptionsMap = {};

    for (var optionGroup in product.options) {
      if (optionGroup is Map && optionGroup.containsKey('name') && optionGroup.containsKey('choices')) {
        final choices = optionGroup['choices'] as List;
        if (choices.isNotEmpty) {
          selectedOptionsMap[optionGroup['name']] = choices[0];
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            double currentPrice = product.price;
            selectedOptionsMap.forEach((key, choice) {
              if (choice is Map && choice.containsKey('price')) {
                currentPrice += (choice['price'] as num).toDouble();
              }
            });

            return AlertDialog(
              title: Text('Pilih Varian: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: product.options.map((optionGroup) {
                      if (optionGroup is! Map || !optionGroup.containsKey('name') || !optionGroup.containsKey('choices')) {
                        return const SizedBox.shrink();
                      }
                      
                      final groupName = optionGroup['name'];
                      final choices = optionGroup['choices'] as List;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Builder(builder: (context) {
                            final currentSelected = selectedOptionsMap[groupName];
                            return Column(
                              children: choices.map((choice) {
                                if (choice is! Map) return const SizedBox.shrink();
                                
                                final choiceName = choice['name'] ?? '';
                                final choicePrice = (choice['price'] as num?)?.toDouble() ?? 0.0;
                                
                                return RadioListTile<String>(
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(choiceName, style: const TextStyle(fontSize: 14)),
                                      if (choicePrice > 0)
                                        Text('+${_currency.format(choicePrice)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                                    ],
                                  ),
                                  value: choiceName,
                                  // ignore: deprecated_member_use
                                  groupValue: currentSelected is Map ? currentSelected['name'] as String? : null,
                                  // ignore: deprecated_member_use
                                  onChanged: (val) {
                                    if (val != null) {
                                      final matched = choices.firstWhere((c) => c is Map && c['name'] == val, orElse: () => null);
                                      if (matched != null) {
                                        setStateSB(() {
                                          selectedOptionsMap[groupName] = matched;
                                        });
                                      }
                                    }
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            );
                          }),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    List<Map<String, dynamic>> finalOptions = [];
                    selectedOptionsMap.forEach((group, choice) {
                      finalOptions.add({
                        'group': group,
                        'name': choice['name'],
                        'price': choice['price'] ?? 0.0,
                      });
                    });
                    
                    cartProv.addItem(product, options: finalOptions);
                    Navigator.pop(ctx);
                    
                    if (context.mounted) {
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
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text('Tambah - ${_currency.format(currentPrice)}'),
                ),
              ],
            );
          },
        );
      },
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
                        hasOptions: product.options.isNotEmpty,
                        onTap: () {
                          if (product.options.isNotEmpty) {
                            _showOptionsDialog(context, product, cartProv);
                          } else {
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
                          }
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
