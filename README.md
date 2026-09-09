<div align="center">
  <img src="assets/images/corevia_logo.jpg" alt="Corevia Logo" width="200" height="200">
  
  # Corevia POS

  <p>
    <b>Aplikasi kasir (Point of Sale) modern yang dibangun menggunakan Flutter dan Supabase.</b>
  </p>

  [![Flutter](https://img.shields.io/badge/Flutter-%5E3.12.2-02569B?logo=flutter)](https://flutter.dev/)
  [![Supabase](https://img.shields.io/badge/Supabase-Database-3ECF8E?logo=supabase)](https://supabase.com/)
</div>

---

Corevia dirancang untuk memudahkan manajemen toko, kasir, transaksi, serta pelaporan keuangan Anda secara terpadu dan real-time.

## 🎯 Fitur Utama

- 🛒 **Manajemen Kasir (POS)**: Kalkulasi harga otomatis, multi-varian/topping, dan fitur *Hold Order* (simpan pesanan sementara).
- 🕒 **Manajemen Shift Kasir**: Fitur buka/tutup shift (Blind Close) dan pencatatan kas keluar harian (Petty Cash).
- 📈 **Admin Dashboard**: Kelola inventaris produk, kategori, pelanggan, dan pegawai. Memantau laporan pendapatan harian/bulanan.
- 💳 **Pembayaran QRIS Dinamis**: *Generate* kode QRIS sesuai total belanja langsung dari layar aplikasi.
- 🖨️ **Cetak Struk**: Mendukung pencetakan struk langsung ke *Bluetooth Thermal Printer*.
- 🔒 **Otentikasi & Keamanan**: Login Admin/Kasir yang aman, auto-logout (Inactivity Wrapper), proteksi perangkat *Root/Jailbreak*, dan **Row Level Security (RLS)** pada database.

---

## 🛠️ Persyaratan Sistem (Prerequisites)

Sebelum menjalankan proyek ini di lokal Anda, pastikan Anda telah menginstal:

1. **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (Versi `^3.12.2` atau terbaru)
2. **[Dart SDK](https://dart.dev/get-dart)** (sudah ter-*bundle* dengan Flutter)
3. Editor Kode (Disarankan: **VS Code** atau **Android Studio**)
4. Akun **[Supabase](https://supabase.com/)** (Jika Anda ingin menggunakan database sendiri).

---

## 🚀 Cara Setup di Lokal (Local Development)

Ikuti langkah-langkah di bawah ini untuk menjalankan aplikasi di mesin lokal Anda:

### 1. Clone Repository
Buka terminal dan jalankan perintah berikut untuk mengunduh kode sumber:
```bash
git clone <URL_REPOSITORY_ANDA>
cd project_pos
```

### 2. Install Dependencies
Unduh semua *package* atau library yang dibutuhkan oleh aplikasi dengan menjalankan:
```bash
flutter pub get
```

### 3. Konfigurasi Backend (Supabase)
Jika Anda ingin menggunakan database milik Anda sendiri (Supabase):
1. Buat proyek baru di [Supabase](https://supabase.com/).
2. Buka menu **SQL Editor** di dashboard Supabase Anda.
3. Buka file `database_schema.sql` yang ada di *root* folder proyek ini, lalu salin (*copy*) semua isinya.
4. Tempel (*paste*) kode SQL tersebut ke Supabase SQL Editor dan jalankan (*RUN*). Perintah ini akan membuat semua tabel yang dibutuhkan beserta akun admin bawaan (Username: `admin`, Password: `admin123`).
5. Buka `lib/config/supabase_config.dart` lalu ganti nilai `supabaseUrl` dan `supabaseAnonKey` dengan kredensial API dari dashboard Supabase Anda.
6. **🚨 KEAMANAN PENTING**: Pastikan Anda **mengaktifkan Row Level Security (RLS)** untuk semua tabel di dashboard Supabase. 

*(Catatan: Aplikasi sudah terhubung ke database demo bawaan secara default, namun data sewaktu-waktu bisa di-reset).*

### 4. Jalankan Aplikasi
Untuk menjalankan aplikasi di *emulator* atau *perangkat asli*, ketik:
```bash
flutter run
```

---

## 📂 Struktur Direktori Utama

Kode aplikasi terpusat di dalam folder `lib/`. Berikut adalah arsitektur MVC/Provider yang digunakan:

```text
lib/
├── models/      # Blueprint/Cetakan struktur data (Produk, Transaksi, dll)
├── providers/   # Logika bisnis dan State Management (Controllers)
├── views/       # Antarmuka pengguna (UI)
├── core/        # Core settings & security
└── utils/       # Helper functions, QRIS, formatters
```

---

## 🔧 Troubleshooting Umum

- **Aplikasi tidak bisa di-build untuk Android**: Pastikan Android SDK dan NDK sudah terpasang dengan benar di Android Studio Anda.
- **Printer Bluetooth tidak terdeteksi**: Pastikan Anda telah memberikan izin (Permission) Lokasi dan Bluetooth di pengaturan perangkat Anda.

---
<div align="center">
  <p><i>Dibuat untuk mempermudah operasional kasir dan pelaporan bisnis secara realtime.</i></p>
</div>
