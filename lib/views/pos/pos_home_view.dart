import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shift_provider.dart';
import '../admin/admin_dashboard_view.dart';
import '../auth/login_view.dart';
import '../maintenance/maintenance_lock_view.dart';
import 'history_view.dart';
import 'widgets/cart_sheet.dart';
import '../../models/product_model.dart';

class PosHomeView extends StatefulWidget {
  const PosHomeView({super.key});

  @override
  State<PosHomeView> createState() => _PosHomeViewState();
}

class _PosHomeViewState extends State<PosHomeView> {
  int _currentTabIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Dialog Manajemen Shift Kasir
  void _showShiftManagementDialog() {
    final shiftProv = context.read<ShiftProvider>();
    final auth = context.read<AuthProvider>();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final startingCashCtrl = TextEditingController(text: '100000');

    showDialog(
      context: context,
      builder: (dialogCtx) => Consumer<ShiftProvider>(
        builder: (ctx, shift, _) {
          final isShiftOpen = shift.isShiftOpen;
          final current = shift.currentShift;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isShiftOpen ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isShiftOpen ? Icons.storefront_rounded : Icons.lock_clock_rounded,
                    color: isShiftOpen ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isShiftOpen ? 'Shift Kasir Aktif' : 'Buka Shift Kasir',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: isShiftOpen
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Kasir Bertugas:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(current?.cashierName ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Modal Awal Kas:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(currency.format(current?.startingCash ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Penjualan Tunai:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(currency.format(current?.cashSales ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Non-Tunai (QRIS/VA):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(currency.format(current?.nonCashSales ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5))),
                                ],
                              ),
                              if ((current?.pettyCashOut ?? 0) > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Kas Keluar (Toko):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text('- ${currency.format(current!.pettyCashOut)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                                  ],
                                ),
                              ],
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Uang Kas Seharusnya:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(currency.format(current?.expectedCashEnd ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.outbox_rounded, size: 16, color: Colors.orange),
                                label: const Text('Kas Keluar', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  _showPettyCashDialog();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                                icon: const Icon(Icons.lock_rounded, size: 16),
                                label: const Text('Tutup Shift', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  _showCloseShiftDialog();
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masukkan nominal modal uang tunai receh di laci kasir saat mulai bertugas:',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: startingCashCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Modal Awal Kasir',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onSubmitted: (val) async {
                            final starting = double.tryParse(val) ?? 100000;
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(dialogCtx);
                            await shiftProv.openShift(auth.currentUser?.name ?? 'Kasir', starting);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Shift Kasir berhasil dibuka!')),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () async {
                              final starting = double.tryParse(startingCashCtrl.text) ?? 100000;
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(dialogCtx);
                              await shiftProv.openShift(auth.currentUser?.name ?? 'Kasir', starting);
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Shift Kasir berhasil dibuka!')),
                              );
                            },
                            child: const Text('Buka Shift Sekarang'),
                          ),
                        )
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  // Dialog Catat Kas Keluar Toko
  void _showPettyCashDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Catat Kas Keluar (Petty Cash)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gunakan untuk mencatat pengeluaran tunai toko dari laci kasir (misal: beli es batu, galon air, kresek).',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Keterangan / Keperluan',
                hintText: 'Misal: Beli Galon',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Uang Keluar',
                prefixText: 'Rp ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(amountCtrl.text) ?? 0;
              final desc = descCtrl.text.trim();
              if (val > 0 && desc.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final shiftProv = context.read<ShiftProvider>();
                Navigator.pop(dialogCtx);
                await shiftProv.recordPettyCash(val, desc);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Kas keluar berhasil dicatat!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nominal dan keterangan harus diisi!')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Dialog Tutup Shift Kasir (Closing)
  void _showCloseShiftDialog() {
    final shift = context.read<ShiftProvider>().currentShift;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final cashEndCtrl = TextEditingController(text: '${shift?.expectedCashEnd.toInt() ?? 0}');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tutup Shift & Rekap Kasir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uang sistem di laci: ${currency.format(shift?.expectedCashEnd ?? 0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cashEndCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Uang Fisik Aktual di Laci Kasir',
                prefixText: 'Rp ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              try {
                final cleanText = cashEndCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                final val = double.tryParse(cleanText) ?? 0.0;
                final messenger = ScaffoldMessenger.of(context);
                final shiftProv = context.read<ShiftProvider>();
                Navigator.pop(dialogCtx);
                await shiftProv.closeShift(val);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Shift kasir berhasil ditutup!')),
                  );
                }
              } catch (e) {
                debugPrint('Close shift UI error: $e');
              }
            },
            child: const Text('Tutup Shift Sekarang'),
          ),
        ],
      ),
    );
  }

  // Dialog Lihat Pesanan yang di-Hold
  void _showHeldOrdersDialog(BuildContext context) {
    final cartProv = context.read<CartProvider>();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pause_circle_filled_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Daftar Antrean Disimpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: cartProv.heldOrders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Tidak ada antrean pesanan yang disimpan.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: cartProv.heldOrders.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (context, i) {
                    final held = cartProv.heldOrders[i];
                    final total = held.items.values.fold(0.0, (s, it) => s + it.subtotal);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(held.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        '${held.items.length} Menu • ${currency.format(total)} • ${DateFormat('HH:mm').format(held.heldAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () {
                              cartProv.deleteHeldOrder(held.id);
                              Navigator.pop(ctx);
                            },
                          ),
                          FilledButton.tonal(
                            child: const Text('Buka'),
                            onPressed: () {
                              cartProv.resumeHeldOrder(held);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Pesanan ${held.label} dibuka kembali!')),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, ProductModel product, CartProvider cartProv) {
    // We create a local state to hold selected options
    Map<String, dynamic> selectedOptionsMap = {};

    // Initialize with default/first options if they exist
    for (var optionGroup in product.options) {
      if (optionGroup is Map && optionGroup.containsKey('name') && optionGroup.containsKey('choices')) {
        final choices = optionGroup['choices'] as List;
        if (choices.isNotEmpty) {
          // Select the first choice by default
          selectedOptionsMap[optionGroup['name']] = choices[0];
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
            
            // Calculate current total price with options
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
                            return RadioGroup<String>(
                              groupValue: currentSelected is Map ? currentSelected['name'] as String? : null,
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
                              child: Column(
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
                                        Text('+${currency.format(choicePrice)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                                    ],
                                  ),
                                  value: choiceName,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
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
                FilledButton.icon(
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text('Tambah - ${currency.format(currentPrice)}'),
                  onPressed: () {
                    // Convert selectedOptionsMap to List<Map<String, dynamic>>
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
                  },
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
    final user = context.watch<AuthProvider>().currentUser;
    final productProv = context.watch<ProductProvider>();
    final cartProv = context.watch<CartProvider>();
    final shiftProv = context.watch<ShiftProvider>();
    final settingsProv = context.watch<SettingsProvider>();

    if (settingsProv.settings.isMaintenance) {
      return const MaintenanceLockView();
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isWideScreen = MediaQuery.of(context).size.width >= 920;

    // Filter produk berdasarkan kategori dan kata kunci pencarian
    final filteredProducts = productProv.products.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF4F46E5), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('KASIR POS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          _PulseDot(color: Colors.green, size: 7),
                          SizedBox(width: 5),
                          Text('ONLINE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${user?.name ?? 'Kasir'} • ${shiftProv.isShiftOpen ? "Shift Aktif" : "Shift Belum Dibuka"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: shiftProv.isShiftOpen ? Colors.green.shade700 : Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Top View Switcher for Desktop / Web
          if (isWideScreen)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.grid_view_rounded, size: 16),
                    label: Text('Katalog Menu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.receipt_long_rounded, size: 16),
                    label: Text('Riwayat Transaksi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
                selected: {_currentTabIndex},
                onSelectionChanged: (set) => setState(() => _currentTabIndex = set.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

          // Shift Kasir Quick Action Button
          ActionChip(
            avatar: Icon(
              shiftProv.isShiftOpen ? Icons.storefront_rounded : Icons.lock_clock_rounded,
              color: shiftProv.isShiftOpen ? Colors.green : Colors.orange,
              size: 16,
            ),
            label: Text(
              shiftProv.isShiftOpen ? 'Shift Aktif' : 'Buka Shift',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: shiftProv.isShiftOpen ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
            backgroundColor: (shiftProv.isShiftOpen ? Colors.green : Colors.orange).withValues(alpha: 0.1),
            side: BorderSide(
              color: (shiftProv.isShiftOpen ? Colors.green : Colors.orange).withValues(alpha: 0.3),
            ),
            onPressed: _showShiftManagementDialog,
          ),
          const SizedBox(width: 6),

          // Held order icon if any
          if (cartProv.heldOrders.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${cartProv.heldOrders.length}'),
                backgroundColor: Colors.orange,
                child: const Icon(Icons.pause_circle_outline_rounded, color: Colors.orange),
              ),
              tooltip: 'Daftar Antrean Disimpan (${cartProv.heldOrders.length})',
              onPressed: () => _showHeldOrdersDialog(context),
            ),

          if (user?.isAdmin == true)
            IconButton.filledTonal(
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
              tooltip: 'Admin Panel',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardView()),
              ),
            ),
          const SizedBox(width: 4),
          IconButton.outlined(
            icon: const Icon(Icons.logout_rounded, size: 18),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _currentTabIndex == 1
          ? const HistoryView()
          : (isWideScreen
              ? Row(
                  children: [
                    // Left Column: Catalog & Menu Grid (Responsive Flex)
                    Expanded(
                      child: _buildCatalogView(productProv, cartProv, filteredProducts, currency),
                    ),
                    // Right Column: Pinned Order Ticket / Cart Panel
                    const SizedBox(
                      width: 400,
                      child: CartSheet(isPinned: true),
                    ),
                  ],
                )
              : _buildCatalogView(productProv, cartProv, filteredProducts, currency)),

      // Bottom Bar Floating Keranjang (Khusus Layar Mobile)
      bottomSheet: (!isWideScreen && _currentTabIndex == 0 && cartProv.items.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Badge(
                      backgroundColor: const Color(0xFF4F46E5),
                      label: Text('${cartProv.totalItemCount}'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF4F46E5), size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pesanan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text(
                            currency.format(cartProv.grandTotal),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const CartSheet(),
                        );
                      },
                      child: const Row(
                        children: [
                          Text('Buka Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          : null,

      // Navigation Bar (Hanya tampil di Mobile jika bukan widescreen)
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: _currentTabIndex,
              onDestinationSelected: (i) => setState(() => _currentTabIndex = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale_rounded),
                  label: 'Kasir POS',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Riwayat Transaksi',
                ),
              ],
            ),
    );
  }

  // Komponen Katalog Menu & Grid POS
  Widget _buildCatalogView(
    ProductProvider productProv,
    CartProvider cartProv,
    List<ProductModel> filteredProducts,
    NumberFormat currency,
  ) {
    return RefreshIndicator(
      onRefresh: () => productProv.fetchProductsAndCategories(),
      child: Column(
        children: [
          // Search Bar & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari menu, kopi, atau makanan...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Category Filter Bar (Pills)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: productProv.categories.map((cat) {
                  final isSelected = productProv.selectedCategory.toLowerCase() == cat.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF4F46E5),
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (_) => productProv.selectCategory(cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Loading or Grid
          Expanded(
            child: productProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty ? 'Menu "$_searchQuery" tidak ditemukan' : 'Belum ada menu di kategori ini',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisExtent: 310,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, i) {
                          final item = filteredProducts[i];
                          final isOutOfStock = item.stock <= 0;
                          final isLowStock = item.stock > 0 && item.stock <= 5;
                          final inCartQty = cartProv.items[item.id]?.quantity ?? 0;

                          return _AnimatedProductCard(
                            item: item,
                            inCartQty: inCartQty,
                            isOutOfStock: isOutOfStock,
                            isLowStock: isLowStock,
                            currency: currency,
                            onTap: () {
                              if (item.options.isNotEmpty) {
                                _showOptionsDialog(context, item, cartProv);
                              } else {
                                cartProv.addItem(item);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Widget Pulsa Bernapas untuk Indikator Status Online / Notifikasi
class _PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulseDot({this.color = Colors.green, this.size = 7});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.75),
              blurRadius: widget.size * 1.6 * _anim.value,
              spreadRadius: widget.size * 0.45 * _anim.value,
            ),
          ],
        ),
      ),
    );
  }
}

// Kartu Produk Animasi Responsif (Hover lift, Tap bounce, Elastic pop badge)
class _AnimatedProductCard extends StatefulWidget {
  final ProductModel item;
  final int inCartQty;
  final bool isOutOfStock;
  final bool isLowStock;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _AnimatedProductCard({
    required this.item,
    required this.inCartQty,
    required this.isOutOfStock,
    required this.isLowStock,
    required this.currency,
    required this.onTap,
  });

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasItemInCart = widget.inCartQty > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.isOutOfStock ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isOutOfStock ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.isOutOfStock ? null : () => setState(() => _isPressed = false),
        onTap: widget.isOutOfStock ? null : widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasItemInCart
                    ? const Color(0xFF4F46E5)
                    : (_isHovered ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0)),
                width: hasItemInCart ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasItemInCart
                      ? const Color(0xFF4F46E5).withValues(alpha: 0.15)
                      : (_isHovered ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03)),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: Offset(0, _isHovered ? 4 : 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty)
                        Image.network(
                          widget.item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                            child: const Icon(Icons.coffee_rounded, size: 40, color: Color(0xFF4F46E5)),
                          ),
                        )
                      else
                        Container(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                          child: const Icon(Icons.coffee_rounded, size: 40, color: Color(0xFF4F46E5)),
                        ),

                      // In-Cart Badge with Elastic Pop Animation
                      Positioned(
                        top: 8,
                        right: 8,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) => ScaleTransition(
                            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                            child: child,
                          ),
                          child: hasItemInCart
                              ? Container(
                                  key: ValueKey(widget.inCartQty),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    'x${widget.inCartQty}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey(0)),
                        ),
                      ),

                      // Out of stock overlay
                      if (widget.isOutOfStock)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('HABIS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),

                // Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.item.category,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: widget.isOutOfStock
                                          ? Colors.red
                                          : (widget.isLowStock ? Colors.orange : Colors.green),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Stok: ${widget.item.stock}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: widget.isOutOfStock
                                            ? Colors.red
                                            : (widget.isLowStock ? Colors.orange.shade800 : const Color(0xFF64748B)),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.currency.format(widget.item.price),
                                  style: const TextStyle(
                                    color: Color(0xFF4F46E5),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.isOutOfStock
                                    ? Colors.grey.shade200
                                    : (hasItemInCart
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFF4F46E5).withValues(alpha: 0.1)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 16,
                                color: widget.isOutOfStock
                                    ? Colors.grey
                                    : (hasItemInCart ? Colors.white : const Color(0xFF4F46E5)),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
