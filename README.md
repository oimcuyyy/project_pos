# Project POS (Point of Sale)

Aplikasi kasir (Point of Sale) modern yang dibangun menggunakan **Flutter** dan **Supabase**. Aplikasi ini dirancang untuk memudahkan manajemen toko, kasir, transaksi, serta pelaporan keuangan.

---

## 🎯 Fitur Utama
- **Manajemen Kasir (POS)**: Kalkulasi harga otomatis, multi-varian/topping, dan fitur *Hold Order* (simpan pesanan sementara).
- **Manajemen Shift Kasir**: Fitur buka/tutup shift (Blind Close) dan pencatatan kas keluar harian (Petty Cash).
- **Admin Dashboard**: Kelola inventaris produk, kategori, pelanggan, dan pegawai. Memantau laporan pendapatan harian/bulanan.
- **Pembayaran QRIS Dinamis**: *Generate* kode QRIS sesuai total belanja langsung dari layar aplikasi.
- **Cetak Struk**: Mendukung pencetakan struk langsung ke *Bluetooth Thermal Printer*.
- **Otentikasi & Keamanan**: Login Admin/Kasir yang aman, auto-logout (Inactivity Wrapper), dan proteksi perangkat *Root/Jailbreak*.

---

## 🛠️ Persyaratan Sistem (Prerequisites)
Sebelum menjalankan proyek ini di lokal Anda, pastikan Anda telah menginstal:
1. **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (Versi `^3.12.2` atau terbaru)
2. **[Dart SDK](https://dart.dev/get-dart)** (sudah ter-*bundle* dengan Flutter)
3. Editor Kode (Disarankan: **VS Code** atau **Android Studio**)
4. Akun [Supabase](https://supabase.com/) (Jika Anda ingin menggunakan database sendiri).

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
4. Tempel (*paste*) kode SQL tersebut ke Supabase SQL Editor dan jalankan (*RUN*). Perintah ini akan membuat semua tabel yang dibutuhkan (Produk, User, Transaksi, Shift, dll) beserta akun admin bawaan (Username: `admin`, Password: `admin123`).
5. Buka `lib/config/supabase_config.dart` lalu ganti nilai `supabaseUrl` dan `supabaseAnonKey` dengan kredensial API dari dashboard Supabase Anda (Settings -> API).
6. **🚨 KEAMANAN PENTING (Wajib Dilakukan)**: Pastikan Anda **mengaktifkan Row Level Security (RLS)** untuk semua tabel di dashboard Supabase. Atur kebijakan (Policies) agar hanya *Authenticated User* (Admin/Kasir yang login) yang dapat menambah/merubah/menghapus data. Jika tidak, database Anda bisa dimanipulasi dengan mudah oleh publik menggunakan *anon key*.

*(Catatan: Jika Anda tidak ingin repot, aplikasi sudah terhubung ke database demo bawaan secara default. Namun, data sewaktu-waktu bisa di-reset).*

### 4. Jalankan Aplikasi
Untuk menjalankan aplikasi di *emulator* atau *perangkat asli*, ketik:
```bash
flutter run
```
Atau Anda bisa langsung menekan tombol `Run` / `F5` jika menggunakan VS Code atau Android Studio.

---

## 📂 Struktur Direktori Utama
Kode aplikasi terpusat di dalam folder `lib/`. Berikut adalah arsitektur MVCS berbasis *Provider* yang digunakan:
- `lib/models/`: Blueprint/Cetakan struktur data (Produk, Keranjang, Transaksi, dll).
- `lib/providers/`: Logika bisnis dan State Management (*Controllers*).
- `lib/views/`: Antarmuka pengguna (UI) untuk Admin, Kasir, Autentikasi, dan Pembayaran.
- `lib/core/` & `lib/utils/`: Utilitas tambahan seperti deteksi root keamanan, format uang, dan helper QRIS.

---

## 🔧 Troubleshooting Umum
- **Aplikasi tidak bisa di-build untuk Android**: Pastikan Android SDK dan NDK sudah terpasang dengan benar di Android Studio Anda.
- **Printer Bluetooth tidak terdeteksi**: Pastikan Anda telah memberikan izin (Permission) Lokasi dan Bluetooth di pengaturan HP/Emulator Anda.

---
*Dibuat untuk mempermudah operasional kasir dan pelaporan bisnis secara realtime.*
