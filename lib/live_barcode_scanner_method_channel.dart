import 'package:flutter/services.dart';

import 'live_barcode_scanner_platform_interface.dart';

/// An implementation of [LiveBarcodeScannerPlatform] that uses method channels.
class MethodChannelLiveBarcodeScanner extends LiveBarcodeScannerPlatform {
  static const _methodChannel = MethodChannel('live_barcode_scanner');
  static const _eventChannel = EventChannel('live_barcode_scanner/events');

  @override
  Future<void> startScan() async {
    await _methodChannel.invokeMethod('startScan');
  }

  @override
  Future<void> stopScan() async {
    await _methodChannel.invokeMethod('stopScan');
  }

  @override
  Future<void> toggleTorch() async {
    await _methodChannel.invokeMethod('toggleTorch');
  }

  @override
  Future<void> setZoom(double zoomFactor) async {
    await _methodChannel.invokeMethod('setZoom', {'zoom': zoomFactor});
  }

  @override
  Stream<String> get scanResults =>
      _eventChannel.receiveBroadcastStream().map((event) => event.toString());
}
