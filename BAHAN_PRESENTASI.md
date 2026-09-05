# 📊 Bahan Presentasi: Project POS (Point of Sale)

Dokumen ini berisi poin-poin utama yang bisa kamu dan kelompokmu gunakan sebagai contekan atau bahan untuk membuat slide presentasi minggu depan.

---

## 1. Latar Belakang & Pendahuluan
**Masalah yang Diselesaikan:**
Banyak usaha kecil hingga menengah (F&B / Kedai Kopi) masih menggunakan sistem kasir manual. Ini sering menyebabkan:
- Kesalahan perhitungan manual.
- Susahnya melacak stok barang.
- Laporan penjualan harian yang tidak akurat.

**Solusi (Project Kami):**
Membangun sebuah aplikasi **Point of Sale (POS) Modern** yang cepat, mudah digunakan, dan terintegrasi dengan sistem *Cloud Database* sehingga manajemen toko dan laporan keuangan bisa dilakukan secara *real-time*.

---

## 2. Teknologi yang Digunakan (Tech Stack)
Aplikasi kita dibangun menggunakan teknologi modern:
- **Frontend (Aplikasi): Flutter**
  - Alasan: Lintas platform (bisa di Android/iOS), performa tinggi, dan UI yang fleksibel.
  - State Management: **Provider** (menggunakan arsitektur MVCS).
- **Backend & Database: Supabase**
  - Alasan: Sebagai alternatif *Open Source* dari Firebase, menggunakan SQL (PostgreSQL) yang sangat handal untuk data transaksional seperti data penjualan.
  - Fitur yang dipakai: Supabase Database, Authentication, dan *Row Level Security* (RLS).

---

## 3. Fitur-Fitur Unggulan (Core Features)

### 🧑‍💻 A. Fitur Kasir (Front-Office)
- **Kalkulasi Otomatis & Varian (Topping/Ukuran):** Harga otomatis disesuaikan jika pembeli memilih ukuran (Small/Medium/Large) atau menambah topping.
- **Hold Order (Simpan Pesanan):** Kasir bisa menyimpan pesanan pelanggan sementara jika pelanggan belum siap membayar, lalu lanjut melayani antrean lain.
- **Pembayaran QRIS Dinamis:** Aplikasi bisa langsung meng-generate kode QRIS di layar sesuai total belanjaan.
- **Cetak Struk Thermal:** Terintegrasi dengan *Bluetooth Thermal Printer* untuk cetak bukti pembayaran langsung dari HP/Tablet.

### 💼 B. Fitur Admin (Back-Office)
- **Admin Dashboard:** Pantau laporan pendapatan harian dan bulanan secara *real-time*.
- **Manajemen Toko:** Kelola inventaris produk, atur kategori, data pelanggan, dan data pegawai.
- **Manajemen Shift Kasir:** Sistem buka-tutup shift kasir (Blind Close) beserta pencatatan kas keluar harian (Petty Cash) agar uang fisik di laci tidak selisih.

### 🛡️ C. Fitur Keamanan (Security)
- **Proteksi Perangkat:** Terdapat deteksi HP *Root/Jailbreak*. (Aplikasi kasir menolak berjalan di HP rakitan/root untuk mencegah manipulasi data).
- **Inactivity Wrapper:** Kasir otomatis ter-logout jika layar tidak disentuh dalam waktu tertentu untuk mencegah penyalahgunaan saat kasir ke toilet.
- **Row Level Security (RLS) di Backend:** Hanya *user* yang sah yang bisa memanipulasi data di *database* Supabase.

---

## 4. Saran Alur Demo saat Presentasi (Demo Flow)
Jika nanti dosen/penguji minta demo aplikasi, gunakan urutan alur ini biar terlihat keren dan profesional:

1. **Login & Buka Shift:** Mulai dengan login sebagai kasir, tunjukkan fitur buka shift dengan memasukkan modal awal (misal: Rp 100.000).
2. **Order & Varian:** Pilih salah satu minuman (misal: Caffe Latte / Matcha Latte). Tunjukkan bahwa kalau kita ubah ukuran (Medium/Large), harganya otomatis bertambah.
3. **Hold Order (Opsional):** Pura-pura pelanggannya dompetnya tertinggal. Tekan fitur *Hold Order*. Lalu buat orderan baru untuk pelanggan lain. Ini pasti bikin dosen terkesan.
4. **Checkout & Bayar QRIS:** Lakukan pembayaran, tunjukkan fitur QRIS yang muncul di layar.
5. **Cetak Struk:** Tunjukkan layar *receipt*/struk bukti pembayaran.
6. **Tutup Shift & Dashboard:** Terakhir, *logout* dari kasir, lalu login sebagai **Admin** untuk menunjukkan laporan pendapatan masuk secara *real-time* dan fitur *Blind Close* shift.

---
*Good luck buat presentasinya minggu depan!* 🚀
