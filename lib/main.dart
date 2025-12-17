import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'input_url_screen.dart';
import 'scanner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.blue;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(
        fontSize: 57,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
      labelLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
    );

    final ThemeData theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primarySeedColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: appTextTheme.labelLarge,
        ),
      ),
    );

    return MaterialApp(
      title: 'Aplikasi Ujian',
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode Kios hanya didukung di Android.')),
      );
      if (mounted) {
        setState(() {
          _isKioskModeActive = true;
        });
      }
      return;
    }

    KioskMode currentKioskMode = await getKioskMode();
    if (!mounted) return;

    if (currentKioskMode == KioskMode.disabled) {
      try {
        await startKioskMode();

        await Future.delayed(const Duration(seconds: 2));

        currentKioskMode = await getKioskMode();
      } catch (e, s) {
        developer.log(
          'Gagal memulai mode kios: $e',
          name: 'KioskMode',
          error: e,
          stackTrace: s,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal mengaktifkan mode kios. Pastikan izin sudah benar.',
            ),
          ),
        );
      }
    }

    if (currentKioskMode == KioskMode.enabled && mounted) {
      setState(() {
        _isKioskModeActive = true;
      });
    } else {
      if (!mounted) return;
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
      } catch (e, s) {
        developer.log(
          'Gagal menghentikan mode kios: $e',
          name: 'KioskMode',
          error: e,
          stackTrace: s,
        );
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
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 30, height: 30),
            SizedBox(width: 10),
            Text('Aplikasi Ujian'),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.blue.shade50,
        child: _isMenuVisible ? _buildMainMenu() : _buildInitialState(),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/images/logo.png', width: 120, height: 120),
            SizedBox(height: 30),
            Text(
              'MA Al-Irsyad',
              style: GoogleFonts.oswald(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Selamat datang di sistem ujian terintegrasi. Silakan aktifkan mode ujian untuk memulai.',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            if (!_isKioskModeActive)
              ElevatedButton.icon(
                onPressed: _activateKioskMode,
                icon: Icon(Icons.security, size: 24),
                label: Text(
                  'Aktifkan Mode Ujian',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(250, 55),
                  elevation: 4,
                ),
              ),
            if (_isKioskModeActive && !_isMenuVisible)
              ElevatedButton.icon(
                onPressed: _showMainMenu,
                icon: Icon(Icons.menu, size: 24),
                label: Text('Buka Menu Utama', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(250, 55),
                  elevation: 4,
                ),
              ),
            SizedBox(height: 30),
            if (_isKioskModeActive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mode Ujian Aktif',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
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

  Widget _buildMainMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(Icons.dashboard, size: 80, color: Colors.blue),
          SizedBox(height: 20),
          Text(
            'Menu Utama',
            style: GoogleFonts.oswald(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              );
            },
            icon: Icon(Icons.qr_code_scanner, size: 28),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Scan QR Code', style: TextStyle(fontSize: 18)),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InputUrlScreen()),
              );
            },
            icon: Icon(Icons.link, size: 28),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Masukkan URL Manual',
                style: TextStyle(fontSize: 18),
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          SizedBox(height: 40),
          Divider(thickness: 1, color: Colors.grey.shade300),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _exitApp,
            icon: Icon(Icons.exit_to_app, size: 28),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Keluar dari Mode Ujian',
                style: TextStyle(fontSize: 18),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Sistem dalam mode ujian terkunci',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
