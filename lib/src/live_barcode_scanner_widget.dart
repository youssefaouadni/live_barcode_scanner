import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that displays the camera preview and scans barcodes live.
class LiveBarcodeScannerWidget extends StatelessWidget {
  const LiveBarcodeScannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidView(viewType: 'live_barcode_scanner_view');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const UiKitView(viewType: 'live_barcode_scanner_view');
    } else {
      return const Center(child: Text('Live scanner not supported on this platform.'));
    }
  }
}
