import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../admin/admin_dashboard_view.dart';
import '../auth/login_view.dart';

class MaintenanceLockView extends StatelessWidget {
  const MaintenanceLockView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>().settings;

    final startedAt = settings.maintenanceStartedAt ?? DateTime.now();
    String formattedTime;
    try {
      formattedTime = DateFormat('EEEE, dd MMMM yyyy • HH:mm:ss', 'id_ID').format(startedAt);
    } catch (_) {
      formattedTime = DateFormat('dd MMM yyyy • HH:mm:ss').format(startedAt);
    }

    final adminName = settings.maintenanceAdminName.isNotEmpty ? settings.maintenanceAdminName : 'Super Admin';
    final message = settings.maintenanceMessage.isNotEmpty
        ? settings.maintenanceMessage
        : 'Sistem kasir dan transaksi sedang dibekukan sementara untuk pemeliharaan keamanan atau audit darurat oleh Admin.';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, anim, child) => Transform.translate(
                offset: Offset(0, 24 * (1 - anim)),
                child: Opacity(
                  opacity: anim.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: Card(
                color: const Color(0xFF131B2E),
                elevation: 12,
                shadowColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.redAccent.shade700.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing Emergency Shield Icon
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.85, end: 1.1),
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeInOut,
                        builder: (context, val, child) => Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFF7F1D1D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.35 * val),
                                blurRadius: 28 * val,
                                spreadRadius: 6 * val,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.security_rounded, size: 54, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.redAccent.shade400.withValues(alpha: 0.6)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 14, color: Colors.redAccent),
                            SizedBox(width: 6),
                            Text(
                              'SECURITY LOCKDOWN • MODE MAINTENANCE AKTIF',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        'SISTEM SEDANG DIKUNCI & DALAM PEMELIHARAAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aplikasi kasir dibekukan total untuk menjaga keamanan data toko & mencegah akses tidak sah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // Message & Detail Information Box
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pesan Informasi
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pesan Informasi Toko:',
                                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFF1E293B), height: 24),

                            // Admin Pengaktif
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
                                    SizedBox(width: 8),
                                    Text('Diaktifkan Oleh:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$adminName (Admin)',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Waktu Pengaktifan
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.access_time_filled_rounded, color: Color(0xFF60A5FA), size: 16),
                                    SizedBox(width: 8),
                                    Text('Waktu Pengaktifan:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                  ],
                                ),
                                Text(
                                  '$formattedTime WIB',
                                  style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Pengamanan (NO ADMIN LOGIN BUTTON)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_person_rounded, size: 18, color: Color(0xFF94A3B8)),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Akses Kasir Ditutup Total • Hanya Dapat Dipulihkan dari Panel Admin',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (auth.currentUser?.isAdmin == true) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.dashboard_rounded, size: 18),
                            label: const Text(
                              'Kembali ke Dashboard Admin (Kontrol Saklar)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminDashboardView()),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF334155)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text(
                              'Kembali ke Halaman Login',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginView()),
                            ),
                          ),
                        ),
                      ],
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
}
