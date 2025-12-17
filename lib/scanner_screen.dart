import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'webview_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Kode QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? url = barcodes.first.rawValue;
            if (url != null &&
                (url.startsWith('http://') || url.startsWith('https://'))) {
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(url: url),
                ),
              );
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Kode QR tidak valid. Pastikan ini adalah URL web.',
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
