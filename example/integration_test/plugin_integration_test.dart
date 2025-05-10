import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:live_barcode_scanner/live_barcode_scanner_platform_interface.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LiveBarcodeScannerPlatform methods execute without error', (tester) async {
    final platform = LiveBarcodeScannerPlatform.instance;

    // Wrap the method calls in try-catch to ensure no exceptions are thrown.
    try {
      // Directly calling methods from the platform interface.
      await platform.startScan();
      await platform.toggleTorch();
      await platform.setZoom(1.5);
      await platform.stopScan();

      // If no exceptions are thrown, the test should pass.
      expect(true, isTrue);
    } catch (e) {
      // If any exception occurs, the test should fail.
      expect(false, isTrue, reason: 'An error occurred: $e');
    }
  });
}
