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
  late final Uri _initialUri;

  bool _isLoading = true;

  // ================= BATTERY =================
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  StreamSubscription<BatteryState>? _batterySubscription;

  // ================= CONNECTIVITY =================
  final Connectivity _connectivity = Connectivity();
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    // Normalisasi URL
    String fixedUrl = widget.url.trim();
    if (!fixedUrl.startsWith('http://') && !fixedUrl.startsWith('https://')) {
      fixedUrl = 'https://$fixedUrl';
    }
    _initialUri = Uri.parse(fixedUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },

          // Abaikan error WebView umum (-1, -6)
          onWebResourceError: (error) {
            if (error.errorCode == -1 || error.errorCode == -6) return;

            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal memuat halaman (${error.errorCode})'),
                backgroundColor: Colors.red,
              ),
            );
          },

          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(_initialUri);

    _monitorBattery();
    _monitorConnectivity();
  }

  // ================= BATTERY =================
  void _monitorBattery() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      if (mounted) setState(() {});

      _batterySubscription = _battery.onBatteryStateChanged.listen((_) async {
        _batteryLevel = await _battery.batteryLevel;
        if (mounted) setState(() {});
      });
    } catch (e, s) {
      developer.log('Battery error', error: e, stackTrace: s);
    }
  }

  // ================= CONNECTIVITY =================
  void _monitorConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
      );
    } catch (e, s) {
      developer.log('Connectivity error', error: e, stackTrace: s);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (!mounted) return;

    if (results.contains(ConnectivityResult.wifi)) {
      _connectivityResult = ConnectivityResult.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _connectivityResult = ConnectivityResult.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      _connectivityResult = ConnectivityResult.ethernet;
    } else {
      _connectivityResult = ConnectivityResult.none;
    }

    setState(() {});
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _batterySubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // ================= BACK =================
  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada halaman sebelumnya'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ================= EXIT =================
  Future<void> _showExitDialog() async {
    final controller = TextEditingController();
    bool enabled = false;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Konfirmasi Keluar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ketik "oke" untuk keluar'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    onChanged: (value) {
                      setDialogState(() {
                        enabled = value.toLowerCase() == 'oke';
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: enabled ? _exitApp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: enabled ? Colors.red : Colors.grey,
                  ),
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
      } catch (_) {}
    }
    SystemNavigator.pop();
  }

  // ================= ICON =================
  IconData _batteryIcon(int level) {
    if (level > 90) return Icons.battery_full;
    if (level > 70) return Icons.battery_6_bar;
    if (level > 50) return Icons.battery_4_bar;
    if (level > 30) return Icons.battery_2_bar;
    if (level > 10) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }

  IconData _connectionIcon(ConnectivityResult result) {
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,

        // ===== HEADER =====
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(78),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade700,
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: Colors.white,
                        onPressed: _handleBack,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        color: Colors.white,
                        onPressed: () => _controller.reload(),
                      ),
                      const Spacer(),

                      Icon(
                        _connectionIcon(_connectivityResult),
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),

                      Icon(
                        _batteryIcon(_batteryLevel),
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_batteryLevel%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol Keluar Aman
                      InkWell(
                        onTap: _showExitDialog,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.exit_to_app,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Keluar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ===== BODY =====
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.2),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
