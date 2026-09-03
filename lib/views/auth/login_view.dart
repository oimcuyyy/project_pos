import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../admin/admin_dashboard_view.dart';
import '../maintenance/maintenance_lock_view.dart';
import '../pos/pos_home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_userController.text, _passController.text);

    if (!mounted) return;
    if (success) {
      if (auth.currentUser!.role == UserRole.admin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardView()),
        );
      } else {
        final settings = context.read<SettingsProvider>().settings;
        if (settings.isMaintenance) {
          auth.logout();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MaintenanceLockView()),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PosHomeView()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Gagal login. Periksa username dan password Anda.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final isWide = MediaQuery.of(context).size.width >= 860;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 880 : 440),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) => Transform.translate(
                offset: Offset(0, 20 * (1 - val)),
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: Card(
                elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Brand Panel
                        Expanded(
                          flex: 5,
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 32),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'POS KASIR & ADMIN',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Sistem kasir cerdas terintegrasi dengan back-office manajemen toko & laporan finansial realtime.',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
                                ),
                                const SizedBox(height: 28),
                                _buildFeatureItem(Icons.bolt_rounded, 'Transaksi Kasir Cepat & Multi-Varian'),
                                const SizedBox(height: 12),
                                _buildFeatureItem(Icons.qr_code_2_rounded, 'QRIS Dinamis & Cetak Struk Bluetooth'),
                                const SizedBox(height: 12),
                                _buildFeatureItem(Icons.analytics_rounded, 'Laporan Omzet, Laba HPP & Shift Kasir'),
                                const SizedBox(height: 28),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
                                      SizedBox(width: 6),
                                      Text('Terminal Siap Digunakan', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Login Form
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: _buildLoginForm(isLoading),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.point_of_sale_rounded, size: 36, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'POS KASIR PINTAR',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Masuk untuk memulai shift atau mengelola toko',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                          const SizedBox(height: 24),
                          _buildLoginForm(isLoading),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF818CF8)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Login Masuk',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Masukkan kredensial akun Anda di bawah ini',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _userController,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'admin / kasir',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _passController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: '••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 20),

        FilledButton(
          onPressed: isLoading ? null : _handleLogin,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Masuk ke Sistem', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ],
    );
  }
}
