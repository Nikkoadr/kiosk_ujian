
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  // Status Indikator
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  StreamSubscription<BatteryState>? _batterySubscription;

  final Connectivity _connectivity = Connectivity();
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Gagal memuat halaman: ${error.description}')),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    _monitorBattery();
    _monitorConnectivity();
  }

  void _monitorBattery() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      if (mounted) setState(() {});

      _batterySubscription = _battery.onBatteryStateChanged.listen((_) async {
        _batteryLevel = await _battery.batteryLevel;
        if (mounted) setState(() {});
      });
    } catch (e, s) {
      developer.log('Gagal memantau baterai: $e', name: 'Battery', error: e, stackTrace: s);
    }
  }

  void _monitorConnectivity() async {
    try {
      final initialResult = await _connectivity.checkConnectivity();
      _updateConnectionStatus(initialResult);

      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    } catch (e, s) {
      developer.log('Gagal memantau konektivitas: $e', name: 'Connectivity', error: e, stackTrace: s);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (!mounted) return;

    var newResult = ConnectivityResult.none;
    if (results.contains(ConnectivityResult.wifi)) {
      newResult = ConnectivityResult.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      newResult = ConnectivityResult.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      newResult = ConnectivityResult.ethernet;
    }

    setState(() {
      _connectivityResult = newResult;
    });
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSimpleBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada halaman sebelumnya untuk kembali.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showExitConfirmationDialog() async {
    final confirmationController = TextEditingController();
    bool isButtonEnabled = false;

    if (!mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Konfirmasi Keluar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Silakan ketik "oke" untuk mengaktifkan tombol keluar.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmationController,
                    decoration: const InputDecoration(
                      labelText: 'Ketik di sini',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        isButtonEnabled = value.toLowerCase() == 'oke';
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonEnabled ? Colors.red : Colors.grey,
                  ),
                  onPressed: isButtonEnabled ? _exitApp : null,
                  child: const Text('Keluar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exitApp() async {
    if (Platform.isAndroid) {
      try {
        await stopKioskMode();
      } catch (e, s) {
        developer.log('Gagal menghentikan mode kios: $e', name: 'KioskMode', error: e, stackTrace: s);
      }
    }
    SystemNavigator.pop();
  }

  IconData _getBatteryIcon(int level) {
    if (level > 90) return Icons.battery_full;
    if (level > 70) return Icons.battery_6_bar;
    if (level > 50) return Icons.battery_4_bar;
    if (level > 30) return Icons.battery_2_bar;
    if (level > 10) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }

  IconData _getConnectivityIcon(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar;
      case ConnectivityResult.ethernet:
        return Icons.settings_ethernet;
      default:
        return Icons.signal_wifi_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getConnectivityIcon(_connectivityResult), size: 20),
              const SizedBox(width: 12),
              Icon(_getBatteryIcon(_batteryLevel), size: 20),
              const SizedBox(width: 6),
              Text(
                '$_batteryLevel%',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          leading: Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 24),
                onPressed: _handleSimpleBack,
                tooltip: 'Kembali',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 24),
                onPressed: () => _controller.reload(),
                tooltip: 'Muat Ulang',
              ),
            ],
          ),
          leadingWidth: 120,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.red, size: 26),
              onPressed: _showExitConfirmationDialog,
              tooltip: 'Keluar',
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
