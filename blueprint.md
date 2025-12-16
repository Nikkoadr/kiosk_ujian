
# Blueprint Aplikasi Ujian Flutter

## Ikhtisar

Aplikasi ujian ini memberlakukan mode kios (*lock task*) yang ketat untuk memastikan integritas selama ujian. Pengguna tidak dapat melanjutkan ke menu utama sampai mode kios berhasil diaktifkan. Setelah masuk ke sesi ujian, pengguna disajikan dengan UI yang imersif, menampilkan status perangkat secara *real-time* dan mekanisme keluar yang aman untuk mencegah kecurangan atau keluar yang tidak disengaja.

## Desain dan Fitur

*   **Tema:** Aplikasi menggunakan tema Material 3 yang terang dan bersih dengan skema warna berbasis **biru dan putih**. Font kustom dari `google_fonts` digunakan untuk memberikan tampilan yang profesional.

*   **Alur Aplikasi Wajib:**
    1.  **Aktivasi Mode Kios:** Saat aplikasi dimulai, pengguna harus mengaktifkan "Mode Ujian" untuk dapat melanjutkan.
    2.  **Validasi Ketat:** Aplikasi memverifikasi bahwa mode kios telah aktif sebelum menampilkan menu utama.
    3.  **Menu Ujian:** Menyediakan dua cara untuk memulai sesi ujian:
        *   **Scan QR:** Membuka kamera untuk memindai QR code yang berisi URL ujian.
        *   **Masukan URL:** Membuka halaman khusus (`InputUrlScreen`) untuk memasukkan URL ujian secara manual, lengkap dengan validasi format URL.
    4.  **Keluar dari Aplikasi:** Tombol "Keluar dari Mode Ujian" di menu utama akan menonaktifkan mode kios terlebih dahulu, lalu menutup aplikasi.

*   **Mode Ujian Ditingkatkan (`WebViewScreen`)
    *   **UI Imersif:** Halaman ujian dirancang untuk fokus penuh tanpa gangguan.
    *   **App Bar Kustom:** `AppBar` standar diganti dengan baris status yang menampilkan informasi penting:
        *   **Profil Pengguna:** Foto (placeholder) dan nama siswa.
        *   **Indikator Status Real-time:**
            *   **Baterai:** Ikon dan persentase level baterai yang diperbarui secara langsung menggunakan *package* `battery_plus`.
            *   **Konektivitas:** Ikon dinamis yang menunjukkan status koneksi (WiFi, data seluler, atau offline) menggunakan `connectivity_plus`.
    *   **Tombol Aksi Penting:**
        *   **Muat Ulang (Reload):** Tombol untuk memuat ulang konten WebView jika diperlukan.
        *   **Keluar (Exit):** Tombol untuk mengakhiri sesi ujian.
    *   **Konfirmasi Keluar yang Aman:** Untuk mencegah keluar yang tidak disengaja, menekan tombol "Keluar" akan menampilkan dialog. Pengguna **wajib mengetik "oke"** pada kolom teks untuk mengaktifkan tombol keluar final.

*   **Navigasi:** Menggunakan `MaterialPageRoute` untuk navigasi antar halaman, termasuk `pushReplacement` untuk memastikan alur yang benar dari halaman input URL ke WebView.

## Rencana Implementasi

1.  **Inisialisasi & Dependensi:**
    *   Panggil `WidgetsFlutterBinding.ensureInitialized()` di `main()`.
    *   Tambahkan dependensi: `google_fonts`, `kiosk_mode`, `mobile_scanner`, `webview_flutter`, `battery_plus`, `connectivity_plus`.
2.  **Implementasi Alur Utama (`main.dart`):
    *   Kelola state untuk aktivasi mode kios dan visibilitas menu.
    *   Arahkan tombol "Scan QR" ke `ScannerScreen`.
    *   Arahkan tombol "Masukan URL" ke `InputUrlScreen`.
3.  **Buat Halaman Input URL (`input_url_screen.dart`):
    *   Gunakan `Form` dan `TextFormField` dengan validasi untuk memastikan input URL benar.
    *   Setelah validasi berhasil, gunakan `Navigator.pushReplacement` untuk membuka `WebViewScreen`.
4.  **Rombak `WebViewScreen` (`webview_screen.dart`):
    *   Gunakan `StatefulWidget` untuk mengelola state lokal.
    *   Pada `initState`, inisialisasi `WebViewController` dan mulai *stream listener* untuk `battery_plus` dan `connectivity_plus`.
    *   Pastikan untuk membatalkan *stream subscription* di `dispose()`.
    *   Bangun `AppBar` kustom dengan `title` berisi profil dan `actions` berisi indikator status serta tombol aksi.
    *   Implementasikan fungsi `_showExitConfirmationDialog` yang berisi `StatefulBuilder` untuk mengelola logika dialog konfirmasi keluar.
    *   Buat fungsi *helper* (`_getBatteryIcon`, `_getConnectivityIcon`) untuk memilih ikon yang sesuai berdasarkan status perangkat.
5.  **Izin Platform:**
    *   Tambahkan `android.permission.CAMERA` di `AndroidManifest.xml` untuk pemindai QR.
