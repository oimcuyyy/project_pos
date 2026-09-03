# Tech Stack & Arsitektur Aplikasi - Project POS

Berikut adalah daftar teknologi, package, dan arsitektur *folder/class* yang digunakan di dalam aplikasi kasir (POS) ini. Panduan ini sangat cocok digunakan sebagai bahan laporan dan presentasi.

---

## 📂 Struktur Folder & Lokasi Class (Architecture)

Aplikasi ini menggunakan pola arsitektur **MVCS (Model-View-Controller/Service)** yang diadaptasi menggunakan arsitektur bawaan Flutter (Provider Pattern). Kode utama berada di dalam folder `lib/`.

### 1. `lib/models/` (Data Models)
Folder ini berisi *Blueprint* (cetakan) data yang merepresentasikan tabel di database. Semua class di sini digunakan untuk mengubah data mentah dari API/Database (JSON) menjadi objek Dart.
- **`product_model.dart`**: Class `ProductModel` untuk data produk, harga, stok, dan daftar varian.
- **`cart_item_model.dart`**: Class `CartItemModel` untuk data item yang dimasukkan ke keranjang kasir beserta varian yang dipilih.
- **`transaction_model.dart`**: Class `TransactionModel` untuk pencatatan transaksi yang sudah selesai.
- **`shift_model.dart`**: Class `ShiftModel` untuk data shift kasir (buka/tutup kasir, modal, selisih uang).
- **`user_model.dart`**: Class `UserModel` untuk data pengguna (admin/kasir).
- **`customer_model.dart`**: Class `CustomerModel` untuk data pelanggan.
- **`store_settings_model.dart`**: Class `StoreSettingsModel` untuk menyimpan pengaturan toko & struk.

### 2. `lib/providers/` (State Management / Controllers)
Berisi *Business Logic* aplikasi. Mengatur bagaimana data diambil dari *backend* (Supabase), diproses, lalu dikirim ke UI. Semua class di sini mewarisi `ChangeNotifier`.
- **`auth_provider.dart`**: Mengatur login, logout, dan sesi kasir/admin.
- **`product_provider.dart`**: Mengambil daftar produk dari database, pencarian, dan pengelolaan varian.
- **`cart_provider.dart`**: Mengelola logika keranjang belanja (tambah/kurang produk, hitung total, diskon, dan fitur *hold order*).
- **`transaction_provider.dart`**: Menyimpan dan mengambil riwayat transaksi.
- **`shift_provider.dart`**: Mengelola pembukaan, pencatatan kas keluar (*petty cash*), dan penutupan shift kasir.
- **`printer_provider.dart`**: Mengatur koneksi Bluetooth ke printer thermal dan logika format cetak struk.
- **`settings_provider.dart`**, **`customer_provider.dart`**, **`employee_provider.dart`**: Manajemen pengaturan toko, member, dan pegawai.

### 3. `lib/views/` (UI / Screens)
Folder ini berisi kode tampilan visual aplikasi (layar yang dilihat oleh pengguna). Dibagi menjadi beberapa sub-folder berdasarkan fungsinya:
- **`admin/`**: 
  - `admin_dashboard_view.dart`: Layar utama untuk panel admin.
  - `report_tab.dart`, `employee_tab.dart`, `customer_tab.dart`: Halaman untuk laporan, pegawai, dan pelanggan.
  - `widgets/options_editor_dialog.dart`: Pop-up untuk menambah/mengedit varian dan topping.
- **`pos/`**: 
  - `pos_home_view.dart`: Layar kasir (Point of Sale) untuk memilih menu.
  - `history_view.dart`: Layar riwayat pesanan.
  - `widgets/cart_sheet.dart`: Komponen sidebar/lembar keranjang belanja di sebelah kanan.
- **`payment/`**:
  - `payment_view.dart`: Layar penyelesaian pembayaran (Tunai/QRIS).
  - `receipt_view.dart`: Layar untuk melihat *preview* struk dan tombol print.
- **`auth/`**:
  - `login_view.dart`: Layar otentikasi (login kasir/admin).

### 4. `lib/core/` & `lib/utils/` (Keamanan & Helper)
- **`core/security/`**:
  - `root_checker.dart`: Mengecek jika HP di-root/jailbreak untuk keamanan.
  - `secure_storage_service.dart`: Menyimpan token login secara aman.
  - `inactivity_wrapper.dart`: Auto-logout jika layar tidak disentuh dalam waktu lama.
- **`utils/qris_helper.dart`**: Fungsi pembantu untuk memanipulasi *string* QRIS agar nilai nominalnya dinamis.

### 5. `lib/config/`
- **`supabase_config.dart`**: Konfigurasi kunci API dan koneksi awal ke server Supabase.
- **`theme.dart`**: Pengaturan warna, font, dan gaya visual utama aplikasi.

---

## 🚀 Core Technologies
- **Flutter SDK** (`^3.12.2`): Framework utama untuk membangun aplikasi multi-platform.
- **Dart**: Bahasa pemrograman utama.
- **Supabase** (`supabase_flutter: ^2.8.0`): Backend-as-a-Service (BaaS) untuk database PostgreSQL dan otentikasi.

## 📦 Package Utama (Dependencies)
- **Provider** (`provider: ^6.1.2`): Digunakan untuk State Management (MVCS).
- **Blue Thermal Printer** (`blue_thermal_printer: ^1.2.3`): Untuk mencetak struk lewat printer Bluetooth.
- **Permission Handler** (`permission_handler: ^11.3.1`): Mengelola izin akses OS (Bluetooth/Lokasi).
- **QR Flutter** (`qr_flutter: ^4.1.0`): Membuat QR Code QRIS Dinamis.
- **Flutter Secure Storage** (`flutter_secure_storage: ^11.0.0`): Menyimpan data token secara aman (enkripsi native Android/iOS).
- **Crypto** (`crypto: ^3.0.7`): Untuk hash dan hitungan matematis seperti validasi keamanan QRIS (CRC16).

## 💡 Highlight Fitur Aplikasi
1. **Kasir (Point of Sale)**: Support kalkulasi otomatis, multi-varian/topping produk, *Hold Order* (Pesanan Gantung), dan cetak struk instan.
2. **Manajemen Shift (Blind Close)**: Kasir harus memasukkan nominal uang fisik laci di akhir shift. Sistem akan membandingkannya dengan catatan database untuk mendeteksi selisih uang. Terdapat fitur Kas Keluar (*Petty cash*).
3. **Admin Dashboard**: Terintegrasi untuk manajemen menu, stok, pantauan *realtime* stok menipis, dan analisis laporan pendapatan.
4. **QRIS Dinamis**: Fitur pembayaran modern yang bisa langsung discan dari layar kasir.
