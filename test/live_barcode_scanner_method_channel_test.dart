import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_barcode_scanner/live_barcode_scanner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('live_barcode_scanner');
  final MethodChannelLiveBarcodeScanner platform =
      MethodChannelLiveBarcodeScanner();

  final List<MethodCall> log = [];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        });
    log.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('startScan calls correct method', () async {
    await platform.startScan();
    expect(log, [
      isA<MethodCall>().having((m) => m.method, 'method', 'startScan'),
    ]);
  });

  test('stopScan calls correct method', () async {
    await platform.stopScan();
    expect(log, [
      isA<MethodCall>().having((m) => m.method, 'method', 'stopScan'),
    ]);
  });

  test('toggleTorch calls correct method', () async {
    await platform.toggleTorch();
    expect(log, [
      isA<MethodCall>().having((m) => m.method, 'method', 'toggleTorch'),
    ]);
  });

  test('setZoom passes correct argument', () async {
    await platform.setZoom(1.5);
    expect(log, [
      isA<MethodCall>().having((m) => m.method, 'method', 'setZoom').having(
        (m) => m.arguments,
        'arguments',
        {'zoom': 1.5},
      ),
    ]);
  });
}
