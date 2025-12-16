
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'input_url_screen.dart';
import 'scanner_screen.dart';

void main() {
  // Memastikan semua Flutter binding sudah siap sebelum aplikasi berjalan.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.blue;

    final TextTheme appTextTheme = TextTheme(
      displayLarge:
          GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
      labelLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
    );

    final ThemeData theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light, // Mengubah ke tema terang
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle:
            GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primarySeedColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: appTextTheme.labelLarge,
        ),
      ),
    );

    return MaterialApp(
      title: 'Aplikasi Ujian', // Menyesuaikan judul
      theme: theme,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isKioskModeActive = false;
  bool _isMenuVisible = false;

  Future<void> _activateKioskMode() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode Kios hanya didukung di Android.'),
        ),
      );
      if (mounted) {
        setState(() {
          _isKioskModeActive = true;
        });
      }
      return;
    }

    KioskMode currentKioskMode = await getKioskMode();

    if (currentKioskMode == KioskMode.disabled) {
      try {
        await startKioskMode();
        currentKioskMode = await getKioskMode();
      } catch (e) {
        print('Gagal memulai mode kios: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Gagal mengaktifkan mode kios. Pastikan izin sudah benar.'),
          ),
        );
      }
    }

    if (currentKioskMode == KioskMode.enabled && mounted) {
      setState(() {
        _isKioskModeActive = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode kios tidak aktif. Tidak dapat melanjutkan.'),
        ),
      );
    }
  }

  Future<void> _exitApp() async {
    if (Platform.isAndroid) {
      try {
        await stopKioskMode();
      } catch (e) {
        print('Gagal menghentikan mode kios: $e');
      }
    }
    SystemNavigator.pop();
  }

  void _showMainMenu() {
    setState(() {
      _isMenuVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Ujian'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!_isKioskModeActive)
              ElevatedButton(
                onPressed: _activateKioskMode,
                child: const Text('Aktifkan Mode Ujian'),
              ),
            if (_isKioskModeActive && !_isMenuVisible)
              ElevatedButton(
                onPressed: _showMainMenu,
                child: const Text('Menu Utama'),
              ),
            if (_isMenuVisible) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScannerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InputUrlScreen()),
                  );
                },
                icon: const Icon(Icons.link),
                label: const Text('Masukan URL'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.list_alt),
                label: const Text('Daftar Soal'),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _exitApp,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Keluar dari Mode Ujian'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
