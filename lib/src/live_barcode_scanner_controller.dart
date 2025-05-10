import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../live_barcode_scanner.dart';
import '../live_barcode_scanner_platform_interface.dart';

class LiveBarcodeScannerController {
  final _platform = LiveBarcodeScannerPlatform.instance;
  StreamSubscription? _subscription;

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> startScan() async {
    if (await _requestCameraPermission()) {
      await _platform.startScan();
    } else {
      debugPrint('Camera permission not granted');
    }
  }

  Future<void> stopScan() async {
    await _platform.stopScan();
    await _subscription?.cancel();
    _subscription = null;
  }


  Future<void> startListening({
    required ValueChanged<String> onScanned,
    required VoidCallback onFailed,
  }) async {
    _subscription = _platform.scanResults.listen(
      (event) {
        debugPrint('Scanned: $event');
        onScanned(event);
      },
      onError: (error) {
        debugPrint('Scanner error: $error');
        onFailed();
      },
    );
  }

  void showBarCodeScanner(
    BuildContext context,
    ValueChanged<String> onResult,
    VoidCallback onFailed,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => _ScannerScreen(
            onScanned: (result) {
              onResult(result);
              Navigator.of(context).pop();
            },
            onFailed: onFailed,
          ),
    ).then((value) {});
  }
}

class _ScannerScreen extends StatefulWidget {
  final ValueChanged<String> onScanned;
  final VoidCallback onFailed;

  const _ScannerScreen({required this.onScanned, required this.onFailed});

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  late final LiveBarcodeScannerController _controller;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = LiveBarcodeScannerController();
    _startScanning();
  }

  Future<void> _startScanning() async {
    await _controller.startScan();
    await _controller.startListening(
      onScanned: (value) {
        widget.onScanned(value);
        _controller.stopScan();
      },
      onFailed: widget.onFailed,
    );
  }

  @override
  void dispose() {
    _controller.stopScan();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const LiveBarcodeScannerWidget(),
        ],
      ),
    );
  }
}
