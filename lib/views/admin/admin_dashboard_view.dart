import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/store_settings_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/qris_helper.dart';
import '../auth/login_view.dart';
import '../pos/pos_home_view.dart';
import '../pos/history_view.dart';
import 'customer_tab.dart';
import 'employee_tab.dart';
import 'report_tab.dart';
import 'widgets/options_editor_dialog.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedNavIndex = 0;
  String _productSearchQuery = '';
  late TextEditingController _maintenanceMessageCtrl;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _maintenanceMessageCtrl = TextEditingController(
      text: 'Sistem kasir dan transaksi sedang dibekukan sementara untuk pemeliharaan keamanan atau audit darurat.',
    );
  }

  @override
  void dispose() {
    _maintenanceMessageCtrl.dispose();
    super.dispose();
  }

  String get _currentFormattedDate {
    try {
      return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.now());
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(DateTime.now());
    }
  }

  // ================= DIALOG CRUD PRODUK =================

  // 1. Form Tambah / Edit Produk
  void _showProductFormDialog(BuildContext context, {ProductModel? product}) {
    final isEditing = product != null;
    final productProv = context.read<ProductProvider>();

    final id = isEditing ? product.id : 'P${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product != null ? product.price.toInt().toString() : '');
    final costPriceCtrl = TextEditingController(text: product != null ? product.costPrice.toInt().toString() : '');
    final stockCtrl = TextEditingController(text: product != null ? product.stock.toString() : '10');
    final imageCtrl = TextEditingController(text: product?.imageUrl ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    List<dynamic> currentOptions = List.from(product?.options ?? []);

    String selectedCategory = product?.category ?? (productProv.categories.length > 1 ? productProv.categories[1] : 'Coffee');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: const Color(0xFF4F46E5)),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Edit Menu Produk' : 'Tambah Menu Baru',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Menu *',
                        hintText: 'Misal: Caramel Macchiato',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: productProv.categories.contains(selectedCategory) ? selectedCategory : null,
                            decoration: InputDecoration(
                              labelText: 'Kategori *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: productProv.categories
                                .where((c) => c != 'All')
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add, size: 20),
                          tooltip: 'Tambah Kategori',
                          onPressed: () => _showAddCategoryDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Harga Jual *',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Harga Modal (HPP)',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Stok *',
                        suffixText: 'pcs',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageCtrl,
                      decoration: InputDecoration(
                        labelText: 'URL Gambar Menu (Opsional)',
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.image_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Singkat (Opsional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                      leading: const Icon(Icons.format_list_bulleted_add),
                      title: const Text('Varian & Topping'),
                      subtitle: Text('${currentOptions.length} grup varian diatur'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showOptionsEditorDialog(context, currentOptions, (newOptions) {
                          setState(() {
                            currentOptions = newOptions;
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  final costPrice = double.tryParse(costPriceCtrl.text) ?? 0;
                  final stock = int.tryParse(stockCtrl.text) ?? 0;

                  if (name.isEmpty || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama produk dan harga jual harus diisi dengan benar!')),
                    );
                    return;
                  }

                  final newProd = ProductModel(
                    id: id,
                    name: name,
                    price: price,
                    costPrice: costPrice,
                    category: selectedCategory,
                    stock: stock,
                    imageUrl: imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null,
                    description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                    options: currentOptions,
                  );

                  Navigator.pop(dialogCtx);

                  if (isEditing) {
                    await productProv.updateProduct(newProd);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Produk ${newProd.name} berhasil diperbarui!')),
                      );
                    }
                  } else {
                    await productProv.addProduct(newProd);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Produk ${newProd.name} berhasil ditambahkan!')),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah Produk'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 2. Dialog Tambah Kategori Baru
  void _showAddCategoryDialog(BuildContext context) {
    final catCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: catCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nama Kategori',
            hintText: 'Misal: Snack, Dessert, Tea',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (catCtrl.text.trim().isNotEmpty) {
                context.read<ProductProvider>().addCategory(catCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kategori "${catCtrl.text.trim()}" berhasil dibuat!')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // 3. Dialog Konfirmasi Hapus Produk
  void _showDeleteConfirmDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}" dari katalog? Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Produk ${product.name} berhasil dihapus!')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // 4. Quick Restock Stok
  void _showAddStockDialog(BuildContext context, ProductModel product) {
    final controller = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          int currentVal = int.tryParse(controller.text) ?? 10;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Tambah Stok: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sisa stok saat ini: ${product.stock} pcs', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.remove),
                        onPressed: currentVal > 1 ? () => setState(() => controller.text = '${currentVal - 1}') : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: InputDecoration(
                            suffixText: 'pcs',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => controller.text = '${currentVal + 1}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 20, 50].map((qty) {
                      return ActionChip(
                        label: Text('+$qty'),
                        onPressed: () => setState(() => controller.text = '$qty'),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
              FilledButton(
                onPressed: () {
                  final qty = int.tryParse(controller.text) ?? 0;
                  if (qty > 0) {
                    context.read<ProductProvider>().addStock(product.id, qty);
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Stok ${product.name} bertambah +$qty pcs!')),
                    );
                  }
                },
                child: const Text('Simpan Stok'),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProv = context.watch<ProductProvider>();
    final shiftProv = context.watch<ShiftProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final trxProv = context.watch<TransactionProvider>();

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isWideScreen = MediaQuery.of(context).size.width >= 960;
    final lowStockCount = productProv.allProducts.where((p) => p.stock <= 5).length;

    final navTitles = [
      'Ringkasan & KPI',
      'Katalog & Stok',
      'Laporan Penjualan',
      'Shift Kasir',
      'Semua Transaksi',
      'Data Pelanggan',
      'Kelola Pegawai',
      'Pengaturan Toko',
      'Mode Maintenance',
    ];

    final currentTitle = navTitles[_selectedNavIndex];

    return Scaffold(
      appBar: isWideScreen
          ? null
          : AppBar(
              title: Text(currentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                  label: const Text('Mode Kasir'),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PosHomeView()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Logout',
                  onPressed: () {
                    auth.logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                  },
                ),
              ],
            ),
      drawer: isWideScreen ? null : Drawer(child: _buildSidebar(context, true, lowStockCount, settingsProv.settings.storeName)),
      body: isWideScreen
          ? Row(
              children: [
                // Left Desktop/Web Sidebar
                _buildSidebar(context, false, lowStockCount, settingsProv.settings.storeName),

                // Right Main Area
                Expanded(
                  child: Column(
                    children: [
                      // Desktop Top Header
                      Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Breadcrumb
                            Expanded(
                              child: Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Admin Back-Office',
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      currentTitle,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Header Actions
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        _currentFormattedDate,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (settingsProv.settings.isMaintenance) ...[
                                  const SizedBox(width: 10),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.white),
                                    label: const Text('MAINTENANCE ON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                    onPressed: () => setState(() => _selectedNavIndex = 8),
                                  ),
                                ],
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                                  label: const Text('Buka Kasir (POS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const PosHomeView()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Main View Area with Smooth Transition
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0.015, 0), end: Offset.zero).animate(animation),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_selectedNavIndex),
                            child: _buildCurrentTab(
                              context,
                              auth,
                              productProv,
                              shiftProv,
                              settingsProv,
                              trxProv,
                              currency,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedNavIndex),
                child: _buildCurrentTab(
                  context,
                  auth,
                  productProv,
                  shiftProv,
                  settingsProv,
                  trxProv,
                  currency,
                ),
              ),
            ),
    );
  }

  // Sidebar Enterprise untuk Desktop dan Mobile Drawer
  Widget _buildSidebar(BuildContext context, bool isDrawer, int lowStockCount, String storeName) {
    final auth = context.read<AuthProvider>();

    final navItems = [
      {'title': 'Ringkasan & KPI', 'icon': Icons.dashboard_rounded},
      {'title': 'Katalog & Stok', 'icon': Icons.inventory_2_rounded},
      {'title': 'Laporan Penjualan', 'icon': Icons.analytics_rounded},
      {'title': 'Shift Kasir', 'icon': Icons.history_toggle_off_rounded},
      {'title': 'Semua Transaksi', 'icon': Icons.receipt_long_rounded},
      {'title': 'Data Pelanggan', 'icon': Icons.people_alt_rounded},
      {'title': 'Kelola Pegawai', 'icon': Icons.badge_rounded},
      {'title': 'Pengaturan Toko', 'icon': Icons.tune_rounded},
      {'title': 'Mode Maintenance', 'icon': Icons.shield_rounded},
    ];

    return Container(
      width: 260,
      color: const Color(0xFF0F172A), // Slate-900 Dark
      child: SafeArea(
        child: Column(
          children: [
            // Store Brand Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName.isNotEmpty ? storeName : 'POS MANAGEMENT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Back-Office Admin',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 12),

            // Navigation List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: navItems.length,
                itemBuilder: (context, i) {
                  final isSelected = _selectedNavIndex == i;
                  final item = navItems[i];
                  final isCatalog = i == 1;
                  final isMaintenanceNav = i == 8;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() => _selectedNavIndex = i);
                          if (isDrawer) Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 3 : 0,
                                height: 16,
                                margin: EdgeInsets.only(right: isSelected ? 8 : 0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Icon(
                                item['icon'] as IconData,
                                size: 20,
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                              if (isCatalog && lowStockCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$lowStockCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (isMaintenanceNav)
                                Consumer<SettingsProvider>(
                                  builder: (context, setProv, _) {
                                    final isMaintenanceOn = setProv.settings.isMaintenance;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isMaintenanceOn ? Colors.red.shade600 : const Color(0xFF334155),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isMaintenanceOn ? 'ON' : 'OFF',
                                        style: TextStyle(
                                          color: isMaintenanceOn ? Colors.white : const Color(0xFF94A3B8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(color: Color(0xFF1E293B), height: 1),

            // Mode Kasir Switcher & Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // User Profile Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF4F46E5),
                          child: Text(
                            (auth.currentUser?.name.isNotEmpty == true)
                                ? auth.currentUser!.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.currentUser?.name ?? 'Admin Toko',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Text('Super Admin', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF94A3B8)),
                          tooltip: 'Logout',
                          onPressed: () {
                            auth.logout();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginView()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Router Navigasi Tab Terpilih
  Widget _buildCurrentTab(
    BuildContext context,
    AuthProvider auth,
    ProductProvider productProv,
    ShiftProvider shiftProv,
    SettingsProvider settingsProv,
    TransactionProvider trxProv,
    NumberFormat currency,
  ) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildOverviewTab(context, auth, productProv, shiftProv, trxProv, currency);
      case 1:
        return _buildCatalogTab(context, productProv, currency);
      case 2:
        return const ReportTab();
      case 3:
        return _buildShiftHistoryTab(context, shiftProv, currency);
      case 4:
        return const HistoryView();
      case 5:
        return const CustomerTab();
      case 6:
        return const EmployeeTab();
      case 7:
        return _StoreSettingsTab(settings: settingsProv.settings, onSave: (updated) => settingsProv.updateSettings(updated));
      case 8:
        return _buildMaintenanceTab(context, auth, settingsProv);
      default:
        return _buildOverviewTab(context, auth, productProv, shiftProv, trxProv, currency);
    }
  }

  // ================= TAB 8: MODE MAINTENANCE & KEAMANAN SISTEM =================
  Widget _buildMaintenanceTab(BuildContext context, AuthProvider auth, SettingsProvider settingsProv) {
    final settings = settingsProv.settings;
    final isMaintenance = settings.isMaintenance;
    final currentAdminName = auth.currentUser?.name ?? 'Super Admin';

    String formattedTime = '-';
    if (settings.maintenanceStartedAt != null) {
      try {
        formattedTime = DateFormat('EEEE, dd MMMM yyyy • HH:mm:ss', 'id_ID').format(settings.maintenanceStartedAt!);
      } catch (_) {
        formattedTime = DateFormat('dd MMM yyyy • HH:mm:ss').format(settings.maintenanceStartedAt!);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isMaintenance ? Icons.security_rounded : Icons.shield_outlined,
                      color: isMaintenance ? Colors.redAccent : const Color(0xFF4F46E5),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Kontrol Mode Maintenance',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Saklar darurat untuk membekukan transaksi kasir seketika jika ada indikasi pembobolan atau audit keamanan.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // KARTU UTAMA SAKLAR ON / OFF
        Card(
          color: isMaintenance ? const Color(0xFF450A0A) : Colors.white,
          elevation: isMaintenance ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isMaintenance ? Colors.redAccent : const Color(0xFFE2E8F0),
              width: isMaintenance ? 2.0 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMaintenance ? Colors.red.shade900.withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMaintenance ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 36,
                    color: isMaintenance ? Colors.redAccent : const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 20),

                // Text Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Status Sistem Kasir: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isMaintenance ? const Color(0xFFFECACA) : const Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMaintenance ? Colors.red.shade700 : const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isMaintenance ? 'MAINTENANCE (ON)' : 'BERJALAN NORMAL (OFF)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isMaintenance
                            ? 'Seluruh kasir sedang dikunci dan tidak dapat memproses pesanan apapun.'
                            : 'Kasir siap digunakan dan dapat melayani transaksi seperti biasa.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isMaintenance ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),

                // TOMBOL SWITCH ON / OFF
                Column(
                  children: [
                    Text(
                      isMaintenance ? 'AKTIF (ON)' : 'MATI (OFF)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isMaintenance ? Colors.redAccent.shade100 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Transform.scale(
                      scale: 1.3,
                      child: Switch(
                        value: isMaintenance,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.redAccent.shade700,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade300,
                        onChanged: (bool enable) async {
                          if (enable) {
                            await settingsProv.setMaintenanceMode(
                              true,
                              adminName: currentAdminName,
                              message: _maintenanceMessageCtrl.text.trim().isNotEmpty
                                  ? _maintenanceMessageCtrl.text.trim()
                                  : 'Sistem kasir dan transaksi sedang dibekukan sementara untuk pemeliharaan keamanan atau audit darurat.',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mode Maintenance DIHUBUNGKAN (ON). Seluruh mesin kasir dibekukan!'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } else {
                            await settingsProv.setMaintenanceMode(false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mode Maintenance DIMATIKAN (OFF). Sistem kasir normal kembali!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // DETAIL INFORMASI & PENGUMUMAN
        Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informasi & Log Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_pin_rounded, size: 16, color: Color(0xFF4F46E5)),
                                SizedBox(width: 6),
                                Text('Admin Penanggung Jawab', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              settings.maintenanceAdminName.isNotEmpty ? settings.maintenanceAdminName : currentAdminName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0EA5E9)),
                                SizedBox(width: 6),
                                Text('Waktu Terakhir Diaktifkan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formattedTime.isNotEmpty && formattedTime != '-' ? '$formattedTime WIB' : 'Belum pernah diaktifkan',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Pesan Pengumuman untuk Kasir:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: _maintenanceMessageCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan pesan yang akan tampil di layar kasir ketika maintenance aktif...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Simpan Pesan Pengumuman', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final updated = settings.copyWith(
                        maintenanceMessage: _maintenanceMessageCtrl.text.trim(),
                      );
                      await settingsProv.updateSettings(updated);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pesan pengumuman berhasil disimpan!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 0: RINGKASAN & KPI EKSEKUTIF =================
  Widget _buildOverviewTab(
    BuildContext context,
    AuthProvider auth,
    ProductProvider productProv,
    ShiftProvider shiftProv,
    TransactionProvider trxProv,
    NumberFormat currency,
  ) {
    final now = DateTime.now();
    final todayTrx = trxProv.transactions.where((t) {
      return t.dateTime.year == now.year && t.dateTime.month == now.month && t.dateTime.day == now.day;
    }).toList();

    final todaySales = todayTrx.fold(0.0, (sum, t) => sum + t.totalAmount);
    final todayProfit = todayTrx.fold(0.0, (sum, t) => sum + t.grossProfit);
    final aov = todayTrx.isNotEmpty ? todaySales / todayTrx.length : 0.0;
    final lowStockItems = productProv.allProducts.where((p) => p.stock <= 5).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await productProv.fetchProductsAndCategories();
        await trxProv.fetchTransactions();
        await shiftProv.fetchShiftHistory();
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Banner Sambutan Eksekutif
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Halo, ${auth.currentUser?.name ?? 'Admin'} 👋',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (shiftProv.isShiftOpen ? Colors.green : Colors.orange).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            shiftProv.isShiftOpen ? 'KASIR AKTIF' : 'SHIFT KASIR DITUTUP',
                            style: TextStyle(
                              color: shiftProv.isShiftOpen ? Colors.greenAccent : Colors.orangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ringkasan real-time performa kasir, transaksi harian, dan inventaris toko Anda.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Menu Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showProductFormDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4 Kartu KPI Metrik
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              return GridView.count(
                crossAxisCount: isNarrow ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: isNarrow ? 1.4 : 1.7,
                children: [
                  _buildStaggeredMetricCard(
                    index: 0,
                    title: 'Omset Hari Ini',
                    value: currency.format(todaySales),
                    subtitle: '${todayTrx.length} pesanan tercatat',
                    icon: Icons.payments_rounded,
                    accentColor: const Color(0xFF10B981),
                  ),
                  _buildStaggeredMetricCard(
                    index: 1,
                    title: 'Total Transaksi',
                    value: '${todayTrx.length} Order',
                    subtitle: 'Rata-rata: ${currency.format(aov)}',
                    icon: Icons.receipt_long_rounded,
                    accentColor: const Color(0xFF4F46E5),
                  ),
                  _buildStaggeredMetricCard(
                    index: 2,
                    title: 'Estimasi Laba Kotor',
                    value: currency.format(todayProfit),
                    subtitle: todaySales > 0 ? 'Margin: ${(todayProfit / todaySales * 100).toStringAsFixed(1)}%' : 'Margin: 0%',
                    icon: Icons.trending_up_rounded,
                    accentColor: const Color(0xFF0EA5E9),
                  ),
                  _buildStaggeredMetricCard(
                    index: 3,
                    title: 'Stok Kritis (<= 5)',
                    value: '${lowStockItems.length} Produk',
                    subtitle: lowStockItems.isEmpty ? 'Semua persediaan aman' : 'Perlu restock segera',
                    icon: Icons.warning_amber_rounded,
                    accentColor: lowStockItems.isEmpty ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Alert Banner Stok Menipis (jika ada)
          if (lowStockItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Peringatan Stok Kritis (${lowStockItems.length} Produk)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red.shade900),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectedNavIndex = 1),
                        child: const Text('Kelola Semua Stok →'),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: lowStockItems.take(6).map((p) {
                        return Container(
                          width: 210,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Sisa: ${p.stock} pcs', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _showAddStockDialog(context, p),
                                  child: const Text('+ Tambah Stok', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Quick Action Bar
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aksi Cepat & Navigasi Operasional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Buka Layar Kasir'),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PosHomeView()),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('Tambah Menu Baru'),
                      onPressed: () => _showProductFormDialog(context),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.category_outlined, size: 18),
                      label: const Text('Tambah Kategori'),
                      onPressed: () => _showAddCategoryDialog(context),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const Text('Lihat Laporan Penjualan'),
                      onPressed: () => setState(() => _selectedNavIndex = 2),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.history_toggle_off_rounded, size: 18),
                      label: const Text('Rekap Shift Kasir'),
                      onPressed: () => setState(() => _selectedNavIndex = 3),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5 Transaksi Terakhir Hari Ini
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('5 Transaksi Terkini Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    TextButton(
                      onPressed: () => setState(() => _selectedNavIndex = 4),
                      child: const Text('Lihat Semua Transaksi →'),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                if (todayTrx.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('Belum ada transaksi yang tercatat hari ini.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayTrx.take(5).length,
                    separatorBuilder: (_, _) => const Divider(height: 12),
                    itemBuilder: (context, i) {
                      final tx = todayTrx[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_rounded, color: Color(0xFF4F46E5), size: 20),
                        ),
                        title: Text(tx.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          '${DateFormat('HH:mm').format(tx.dateTime)} • Kasir: ${tx.cashierName} • ${tx.customerName ?? "Umum"}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currency.format(tx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              tx.paymentMethod.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tx.paymentMethod == PaymentMethod.cash ? Colors.green.shade700 : const Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStaggeredMetricCard({
    required int index,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, anim, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - anim)),
          child: Opacity(
            opacity: anim.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: _buildMetricCard(
        title: title,
        value: value,
        subtitle: subtitle,
        icon: icon,
        accentColor: accentColor,
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle, 
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        ],
      ),
    );
  }

  // ================= TAB 1: KATALOG & CRUD PRODUK =================
  Widget _buildCatalogTab(BuildContext context, ProductProvider productProv, NumberFormat currency) {
    final filteredProducts = productProv.allProducts.where((p) {
      if (_productSearchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_productSearchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_productSearchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: () => productProv.fetchProductsAndCategories(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Top Action Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari menu atau kategori...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  onChanged: (val) => setState(() => _productSearchQuery = val),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Menu Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showProductFormDialog(context),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.category_outlined, size: 18),
                label: const Text('Kategori'),
                onPressed: () => _showAddCategoryDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metrics Quick Card
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Menu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('${productProv.allProducts.length} Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stok Menipis (<=5)', style: TextStyle(fontSize: 11, color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(
                        '${productProv.allProducts.where((p) => p.stock <= 5).length} Produk',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List Produk
          ...filteredProducts.map((p) {
            final isLow = p.stock <= 5;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? Image.network(
                          p.imageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            child: const Icon(Icons.coffee_rounded, color: Color(0xFF4F46E5)),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          child: const Icon(Icons.coffee_rounded, color: Color(0xFF4F46E5)),
                        ),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  '${p.category} • Jual: ${currency.format(p.price)} ${p.costPrice > 0 ? "• Modal: ${currency.format(p.costPrice)}" : ""}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isLow ? Colors.red.shade200 : Colors.green.shade200),
                      ),
                      child: Text(
                        '${p.stock} pcs',
                        style: TextStyle(
                          color: isLow ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_box_rounded, color: Color(0xFF4F46E5), size: 20),
                      tooltip: 'Restock Stok',
                      onPressed: () => _showAddStockDialog(context, p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                      tooltip: 'Edit Menu',
                      onPressed: () => _showProductFormDialog(context, product: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: 'Hapus Menu',
                      onPressed: () => _showDeleteConfirmDialog(context, p),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= TAB 3: RIWAYAT SHIFT KASIR =================
  Widget _buildShiftHistoryTab(BuildContext context, ShiftProvider shiftProv, NumberFormat currency) {
    return RefreshIndicator(
      onRefresh: () => shiftProv.fetchShiftHistory(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Riwayat Penutupan Shift & Kasir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (shiftProv.shiftHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Belum ada riwayat shift kasir tercatat.'),
              ),
            )
          else
            ...shiftProv.shiftHistory.map((s) {
              final isClosed = s.status == 'closed';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(isClosed ? Icons.check_circle_rounded : Icons.pending_rounded,
                                  color: isClosed ? Colors.green : Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Kasir: ${s.cashierName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isClosed ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isClosed ? 'CLOSED' : 'OPEN',
                              style: TextStyle(
                                color: isClosed ? Colors.green.shade700 : Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buka: ${DateFormat('dd/MM/yyyy HH:mm').format(s.openedAt)} ${s.closedAt != null ? "• Tutup: ${DateFormat('HH:mm').format(s.closedAt!)}" : ""}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Modal Awal: ${currency.format(s.startingCash)}', style: const TextStyle(fontSize: 12)),
                          Text('Penjualan Tunai: ${currency.format(s.cashSales)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (s.pettyCashOut > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Kas Keluar: - ${currency.format(s.pettyCashOut)}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                      if (isClosed) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Fisik Laci: ${currency.format(s.actualCashEnd)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(
                              s.difference == 0 ? 'Selisih: Pas (Rp 0)' : 'Selisih: ${currency.format(s.difference)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: s.difference == 0 ? Colors.green : (s.difference < 0 ? Colors.red : Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            })
        ],
      ),
    );
  }
}

class _StoreSettingsTab extends StatefulWidget {
  final StoreSettingsModel settings;
  final Function(StoreSettingsModel) onSave;

  const _StoreSettingsTab({required this.settings, required this.onSave});

  @override
  State<_StoreSettingsTab> createState() => _StoreSettingsTabState();
}

class _StoreSettingsTabState extends State<_StoreSettingsTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _footerCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _serviceCtrl;
  late TextEditingController _qrisCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.settings.storeName);
    _addressCtrl = TextEditingController(text: widget.settings.address);
    _phoneCtrl = TextEditingController(text: widget.settings.phone);
    _footerCtrl = TextEditingController(text: widget.settings.footerMessage);
    _taxCtrl = TextEditingController(text: widget.settings.taxPercent.toInt().toString());
    _serviceCtrl = TextEditingController(text: widget.settings.serviceChargePercent.toInt().toString());
    _qrisCtrl = TextEditingController(text: widget.settings.qrisString);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _footerCtrl.dispose();
    _taxCtrl.dispose();
    _serviceCtrl.dispose();
    _qrisCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQris = _qrisCtrl.text.trim();
    final isValidCrc = currentQris.isNotEmpty && QrisHelper.validateCrc(currentQris);
    final parsedInfo = currentQris.isNotEmpty ? QrisHelper.parseQrisInfo(currentQris) : <String, String>{};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Identitas Toko & Header Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(labelText: 'Nama Toko / Cafe', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressCtrl,
          decoration: InputDecoration(labelText: 'Alamat Toko', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          decoration: InputDecoration(labelText: 'Nomor Telepon / WhatsApp Toko', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _footerCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Pesan Footer Struk',
            hintText: 'Misal: Terima kasih atas kunjungannya! Follow @kopinusantara',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Pengaturan QRIS Statis Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        const Text(
          'String QRIS Statis ini akan otomatis dikonversi menjadi QRIS Dinamis (dengan nominal transaksi) saat kasir melakukan transaksi.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _qrisCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: 'Payload String QRIS Statis',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.restore_rounded),
              tooltip: 'Reset ke QRIS Default (QRIS.jpeg)',
              onPressed: () {
                setState(() {
                  _qrisCtrl.text = QrisHelper.defaultStaticQris;
                });
              },
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        // Live Validation & Info Badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isValidCrc ? Colors.green.shade50 : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isValidCrc ? Colors.green.shade300 : Colors.amber.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isValidCrc ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: isValidCrc ? Colors.green.shade700 : Colors.amber.shade800,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isValidCrc ? 'Checksum CRC16 Valid' : 'Format QRIS Tidak Valid / Belum Diisi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isValidCrc ? Colors.green.shade800 : Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              if (isValidCrc && parsedInfo.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Merchant: ${parsedInfo['merchant_name'] ?? '-'} | NMID: ${parsedInfo['nmid'] ?? '-'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Kota: ${parsedInfo['city'] ?? '-'} (${parsedInfo['postal_code'] ?? '-'})',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Pajak & Biaya Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taxCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Pajak (PPN)', suffixText: '%', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _serviceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Service Charge', suffixText: '%', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.save_rounded),
          label: const Text('Simpan Pengaturan Toko', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            final updated = widget.settings.copyWith(
              storeName: _nameCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              footerMessage: _footerCtrl.text.trim(),
              taxPercent: double.tryParse(_taxCtrl.text) ?? 0,
              serviceChargePercent: double.tryParse(_serviceCtrl.text) ?? 0,
              qrisString: _qrisCtrl.text.trim().isNotEmpty ? _qrisCtrl.text.trim() : QrisHelper.defaultStaticQris,
            );
            widget.onSave(updated);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengaturan toko & QRIS berhasil disimpan!')),
            );
          },
        ),
        const SizedBox(height: 24),
        Card(
          color: widget.settings.isMaintenance ? const Color(0xFF450A0A) : const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.settings.isMaintenance ? Colors.redAccent : const Color(0xFFE2E8F0),
            ),
          ),
          child: ListTile(
            leading: Icon(
              widget.settings.isMaintenance ? Icons.lock_rounded : Icons.shield_rounded,
              color: widget.settings.isMaintenance ? Colors.redAccent : const Color(0xFF4F46E5),
            ),
            title: const Text('Mode Maintenance & Keamanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              widget.settings.isMaintenance
                  ? 'Status: AKTIF (ON) - Seluruh kasir dibekukan.'
                  : 'Status: NORMAL (OFF) - Buka menu "Mode Maintenance" di sidebar untuk saklar ON / OFF.',
              style: TextStyle(
                color: widget.settings.isMaintenance ? Colors.redAccent : const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.settings.isMaintenance ? Colors.red.shade700 : const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.settings.isMaintenance ? 'ON' : 'OFF',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
