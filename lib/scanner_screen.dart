
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'webview_screen.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Kode QR'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? url = barcodes.first.rawValue;
            if (url != null && (url.startsWith('http://') || url.startsWith('https://'))) {
              // Hentikan pemindaian dan navigasi ke WebView
              Navigator.pop(context); // Kembali dari scanner
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(url: url),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kode QR tidak valid. Pastikan ini adalah URL web.'),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
