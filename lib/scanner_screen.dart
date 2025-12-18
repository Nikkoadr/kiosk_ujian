import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'webview_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false; // Flag to prevent multiple navigations

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Kode QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isProcessing) return; // Don't process if already processing

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            setState(() {
              _isProcessing = true;
            });

            String? url = barcodes.first.rawValue;
            if (url != null && url.trim().isNotEmpty) {
              // Automatically add https:// if the scheme is missing
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                url = 'https://$url';
              }

              // Validate that the result is an absolute URL
              if (Uri.tryParse(url)?.isAbsolute ?? false) {
                if (!mounted) return;
                // Pop the scanner screen and push the webview screen
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(url: url!),
                  ),
                ).then((_) {
                  // Reset flag when returning from WebView
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                });
              } else {
                _showInvalidQrCodeSnackBar();
              }
            } else {
              _showInvalidQrCodeSnackBar();
            }
          }
        },
      ),
    );
  }

  void _showInvalidQrCodeSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode QR tidak valid. Pastikan ini adalah URL web.'),
        backgroundColor: Colors.red,
      ),
    );
    // Reset the flag if the QR code is invalid to allow for re-scanning
    setState(() {
      _isProcessing = false;
    });
  }
}
