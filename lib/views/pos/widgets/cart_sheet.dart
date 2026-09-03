import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/shift_provider.dart';
import '../../../models/customer_model.dart';
import '../../payment/payment_view.dart';

class CartSheet extends StatelessWidget {
  final bool isPinned;
  const CartSheet({super.key, this.isPinned = false});

  void _showDiscountDialog(BuildContext context) {
    final cart = context.read<CartProvider>();
    final amountCtrl = TextEditingController(
      text: cart.discountPercent > 0 ? '' : (cart.discountAmount > 0 ? cart.discountAmount.toInt().toString() : ''),
    );
    final percentCtrl = TextEditingController(
      text: cart.discountPercent > 0 ? cart.discountPercent.toInt().toString() : '',
    );
    int activeType = cart.discountPercent > 0 ? 1 : 0; // 0: Nominal, 1: Persen

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.discount_rounded, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text('Atur Diskon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Nominal (Rp)')),
                      ButtonSegment(value: 1, label: Text('Persentase (%)')),
                    ],
                    selected: {activeType},
                    onSelectionChanged: (set) {
                      setState(() => activeType = set.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (activeType == 0)
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Nominal Potongan',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    TextField(
                      controller: percentCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Persentase Diskon',
                        suffixText: '%',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (activeType == 1)
                    Wrap(
                      spacing: 8,
                      children: [5, 10, 15, 20, 50].map((pct) {
                        return ActionChip(
                          label: Text('$pct%'),
                          onPressed: () {
                            setState(() => percentCtrl.text = '$pct');
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cart.setDiscount(amount: 0, percent: 0);
                  Navigator.pop(ctx);
                },
                child: const Text('Hapus Diskon', style: TextStyle(color: Colors.red)),
              ),
              FilledButton(
                onPressed: () {
                  if (activeType == 0) {
                    final val = double.tryParse(amountCtrl.text) ?? 0;
                    cart.setDiscount(amount: val, percent: 0);
                  } else {
                    final val = double.tryParse(percentCtrl.text) ?? 0;
                    cart.setDiscount(amount: 0, percent: val);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHoldOrderDialog(BuildContext context) {
    final cart = context.read<CartProvider>();
    final labelCtrl = TextEditingController(
      text: cart.tableNumber != null && cart.tableNumber!.isNotEmpty
          ? 'Meja ${cart.tableNumber}'
          : (cart.customerName != null && cart.customerName!.isNotEmpty ? cart.customerName : ''),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Simpan Antrean (Hold Order)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesanan ini akan disimpan sementara dan Anda dapat melayani antrean lain terlebih dahulu.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                labelText: 'Label / Catatan Antrean',
                hintText: 'Misal: Meja 4 / Kak Budi',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (labelCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Label Antrean wajib diisi!')),
                );
                return;
              }
              final ok = cart.holdCurrentOrder(labelCtrl.text.trim());
              Navigator.pop(ctx); // Tutup dialog
              if (ok) {
                if (!isPinned) {
                  Navigator.pop(context); // Tutup sheet jika modal
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pesanan berhasil disimpan di daftar antrean!')),
                );
              }
            },
            child: const Text('Simpan Antrean'),
          ),
        ],
      ),
    );
  }

  void _showOrderInfoDialog(BuildContext context) {
    final cart = context.read<CartProvider>();
    final custProv = context.read<CustomerProvider>();
    final isTakeAway = cart.orderType == 'Take Away';
    final tableCtrl = TextEditingController(text: cart.tableNumber ?? '');
    final nameCtrl = TextEditingController(text: cart.customerName ?? '');
    final phoneCtrl = TextEditingController(text: cart.customerPhone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isTakeAway ? 'Info Pelanggan (Take Away)' : 'Info Pelanggan & Meja'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isTakeAway)
                TextField(
                  controller: tableCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nomor Meja *',
                    prefixIcon: const Icon(Icons.table_restaurant_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                TextField(
                  controller: tableCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nomor Antrean / Catatan Meja (Opsional)',
                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 12),
              Autocomplete<CustomerModel>(
                initialValue: TextEditingValue(text: cart.customerName ?? ''),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<CustomerModel>.empty();
                  }
                  return custProv.customers.where((CustomerModel c) {
                    return c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) || 
                           (c.phone != null && c.phone!.contains(textEditingValue.text));
                  });
                },
                displayStringForOption: (CustomerModel option) => option.name,
                onSelected: (CustomerModel selection) {
                  nameCtrl.text = selection.name;
                  if (selection.phone != null) {
                    phoneCtrl.text = selection.phone!;
                    setDialogState(() {});
                  }
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) => nameCtrl.text = val,
                    decoration: InputDecoration(
                      labelText: 'Cari / Input Nama Pelanggan *',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'No. WhatsApp (Opsional)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final table = tableCtrl.text.trim();
                final name = nameCtrl.text.trim();
                
                if ((!isTakeAway && table.isEmpty) || name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(!isTakeAway
                          ? 'Nomor Meja dan Nama Pelanggan wajib diisi!'
                          : 'Nama Pelanggan wajib diisi!'),
                    ),
                  );
                  return;
                }

                cart.setTableNumber(table.isNotEmpty ? table : null);
                cart.setCustomerInfo(
                  name,
                  phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                );
                
                // Jika nama diisi tapi belum ada di db, otomatis simpan ke db
                final phone = phoneCtrl.text.trim();
                final exists = custProv.customers.any((c) => c.name.toLowerCase() == name.toLowerCase());
                if (!exists) {
                  await custProv.addCustomer(CustomerModel(id: '', name: name, phone: phone.isEmpty ? null : phone));
                }

                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final shiftProv = context.watch<ShiftProvider>();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Sync tax & service settings to cart
    if (cart.taxPercent != settings.taxPercent || cart.serviceChargePercent != settings.serviceChargePercent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cart.setTaxAndService(tax: settings.taxPercent, service: settings.serviceChargePercent);
      });
    }

    return Container(
      height: isPinned ? double.infinity : MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isPinned ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(24)),
        border: isPinned ? const Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)) : null,
      ),
      child: Column(
        children: [
          // Header Keranjang
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    Text(
                      isPinned ? 'Order Ticket' : 'Keranjang Belanja',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                        child: child,
                      ),
                      child: Container(
                        key: ValueKey(cart.items.length),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cart.items.length} item',
                          style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.pause_circle_outline_rounded, size: 20, color: Colors.orange),
                      tooltip: 'Simpan Antrean (Hold)',
                      onPressed: cart.itemList.isEmpty ? null : () => _showHoldOrderDialog(context),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      tooltip: 'Kosongkan Keranjang',
                      onPressed: cart.itemList.isEmpty
                          ? null
                          : () {
                              cart.clearCart();
                              if (!isPinned) {
                                Navigator.pop(context);
                              }
                            },
                    ),
                  ],
                )
              ],
            ),
          ),
          
          // Toggle Tipe Pesanan & Meja
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Dine In', label: Text('Dine In')),
                    ButtonSegment(value: 'Take Away', label: Text('Take Away')),
                  ],
                  selected: {cart.orderType},
                  onSelectionChanged: (set) => cart.setOrderType(set.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                TextButton.icon(
                  icon: Icon(cart.orderType == 'Take Away' ? Icons.takeout_dining_rounded : Icons.table_bar_rounded, size: 18),
                  label: Text(
                    cart.orderType == 'Take Away'
                        ? (cart.customerName != null && cart.customerName!.isNotEmpty
                            ? 'Take Away: ${cart.customerName}'
                            : 'Nama Tamu *')
                        : ((cart.tableNumber != null && cart.customerName != null) 
                            ? 'Meja ${cart.tableNumber} - ${cart.customerName}' 
                            : 'Meja & Tamu *'),
                    style: TextStyle(
                      color: ((cart.orderType == 'Dine In' && cart.tableNumber == null) || cart.customerName == null)
                          ? Colors.red
                          : const Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _showOrderInfoDialog(context),
                )
              ],
            ),
          ),
          const Divider(height: 1),

          // List Produk dalam Keranjang
          Expanded(
            child: cart.itemList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Keranjang masih kosong', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: cart.itemList.length,
                    itemBuilder: (context, i) {
                      final item = cart.itemList[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      item.product.imageUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, color: Colors.grey)),
                                    )
                                  : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, color: Colors.grey)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  if (item.selectedOptions.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                                      child: Text(
                                        item.selectedOptions.map((opt) {
                                          final optPrice = (opt['price'] as num?)?.toDouble() ?? 0.0;
                                          final priceStr = optPrice > 0 ? ' (+${currency.format(optPrice)})' : '';
                                          return '${opt['name']}$priceStr';
                                        }).join(', '),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currency.format(item.subtotal / item.quantity), // price per unit including variants
                                    style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () => cart.decreaseQuantity(item.uniqueId),
                                ),
                                Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                IconButton.filledTonal(
                                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () => cart.addItem(item.product, options: item.selectedOptions),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Bagian Total & Pembayaran
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text(currency.format(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Diskon Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _showDiscountDialog(context),
                        child: Row(
                          children: [
                            const Icon(Icons.discount_outlined, size: 14, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 4),
                            Text(
                              cart.discountValue > 0
                                  ? 'Diskon (${cart.discountPercent > 0 ? "${cart.discountPercent.toInt()}%" : "Rp"})'
                                  : 'Tambah Diskon',
                              style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        cart.discountValue > 0 ? '- ${currency.format(cart.discountValue)}' : 'Rp 0',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cart.discountValue > 0 ? Colors.green : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  if (cart.taxValue > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pajak (${settings.taxPercent.toInt()}%)', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text(currency.format(cart.taxValue), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],

                  if (cart.serviceChargeValue > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Service Charge (${settings.serviceChargePercent.toInt()}%)', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        Text(currency.format(cart.serviceChargeValue), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],

                  const Divider(height: 16),

                  // Grand Total & Tombol Checkout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(animation),
                                child: child,
                              ),
                            ),
                            child: Text(
                              currency.format(cart.grandTotal),
                              key: ValueKey(cart.grandTotal),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: shiftProv.isShiftOpen ? const Color(0xFF4F46E5) : Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: cart.itemList.isEmpty
                            ? null
                            : () {
                                if (!shiftProv.isShiftOpen) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.lock_clock_rounded, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('Shift Belum Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: const Text('Anda tidak dapat melakukan transaksi karena Shift Kasir belum dibuka.\n\nHarap buka shift terlebih dahulu melalui tombol ikon shift di pojok kanan atas layar kasir.'),
                                      actions: [
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Mengerti'),
                                        )
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                final isDineIn = cart.orderType == 'Dine In';
                                final missingTable = isDineIn && (cart.tableNumber == null || cart.tableNumber!.trim().isEmpty);
                                final missingCustomer = cart.customerName == null || cart.customerName!.trim().isEmpty;

                                if (missingTable || missingCustomer) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('Data Belum Lengkap', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: Text(isDineIn
                                          ? 'Mohon lengkapi Nomor Meja dan Nama Pelanggan terlebih dahulu sebelum melanjutkan ke pembayaran.\n\nSilakan klik tombol "Meja & Tamu".'
                                          : 'Mohon lengkapi Nama Pelanggan terlebih dahulu sebelum melanjutkan ke pembayaran.\n\nSilakan klik tombol "Nama Tamu".'),
                                      actions: [
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Mengerti'),
                                        )
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                if (!isPinned) {
                                  Navigator.pop(context); // Tutup sheet jika modal
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PaymentView()),
                                );
                              },
                        icon: Icon(shiftProv.isShiftOpen ? Icons.payments_outlined : Icons.lock_rounded, size: 18),
                        label: Text(shiftProv.isShiftOpen ? 'Checkout' : 'Shift Terkunci', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
