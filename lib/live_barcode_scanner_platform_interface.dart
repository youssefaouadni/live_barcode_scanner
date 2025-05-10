import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'live_barcode_scanner_method_channel.dart';

abstract class LiveBarcodeScannerPlatform extends PlatformInterface {
  LiveBarcodeScannerPlatform() : super(token: _token);

  static final Object _token = Object();
  static LiveBarcodeScannerPlatform _instance = MethodChannelLiveBarcodeScanner();

  static LiveBarcodeScannerPlatform get instance => _instance;

  static set instance(LiveBarcodeScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> startScan();
  Future<void> stopScan();
  Future<void> toggleTorch();
  Future<void> setZoom(double zoomFactor);
  Stream<String> get scanResults;
}
