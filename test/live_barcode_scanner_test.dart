import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:ml_kit_live_barcode_scanner/live_barcode_scanner_method_channel.dart';

void main() {
  const MethodChannel channel = MethodChannel('live_barcode_scanner');
  final List<MethodCall> log = [];
  final platform = MethodChannelLiveBarcodeScanner();

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('LiveBarcodeScannerPlatform calls method channel methods', () async {
    // Simulating the method calls through platform
    await platform.startScan();
    await platform.setZoom(2.0);
    await platform.toggleTorch();
    await platform.stopScan();

    // Verifying that the methods were called
    expect(
      log.map((m) => m.method),
      containsAll(['startScan', 'setZoom', 'toggleTorch', 'stopScan']),
    );
  });
}
