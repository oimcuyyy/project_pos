import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'core/security/inactivity_wrapper.dart';
import 'core/security/root_checker.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/printer_provider.dart';
import 'providers/product_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/shift_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/employee_provider.dart';
import 'views/auth/login_view.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi format tanggal & locale
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('DateFormatting init warning: $e');
  }

  // Cek Root / Jailbreak
  await RootCheckerService.verifyDeviceIntegrity();

  // Inisialisasi Supabase
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ShiftProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: const PosApp(),
    ),
  );
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InactivityWrapper(
      timeout: const Duration(minutes: 5), // Auto-lock setelah 5 menit diam
      onTimeout: () {
        // Jika sedang tidak di halaman login, paksa kembali ke halaman login
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        if (authProv.isAuthenticated) {
          authProv.logout();
          globalNavigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginView()),
            (route) => false,
          );
          final navContext = globalNavigatorKey.currentContext;
          if (navContext != null) {
            ScaffoldMessenger.of(navContext).showSnackBar(
              const SnackBar(
                content: Text('Sesi telah dikunci otomatis karena tidak ada aktivitas.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      },
      child: MaterialApp(
        navigatorKey: globalNavigatorKey,
        title: 'POS Kasir Pintar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginView(),
      ),
    );
  }
}

