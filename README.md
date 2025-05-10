# Live Barcode Scanner

A Flutter package for real-time barcode scanning on iOS and Android. This package provides a customizable barcode scanner with a native camera preview, animated scan line, torch control, and zoom functionality. It supports a variety of barcode formats and streams scan results to your Flutter app via an event channel.

## Features

- **Real-Time Scanning**: Detects barcodes in real-time using the device’s camera.
- **Supported Barcode Formats**: EAN-13, EAN-8, PDF417, QR, UPC-E, Code 128, Code 39, Aztec (and more, depending on device capabilities).
- **Customizable Scan Frame**: Adjust the size of the scan area with a visible border and animated scan line.
- **Torch Control**: Toggle the camera flash to scan in low-light conditions.
- **Zoom Support**: Programmatically adjust the camera zoom level.
- **Event Streaming**: Receive barcode data and error events via Flutter’s `EventChannel`.
- **Cross-Platform**: Native implementations for iOS (AVFoundation) and Android (assumed CameraX or equivalent).

## Installation

Add `live_barcode_scanner` to your `pubspec.yaml`:

```yaml
dependencies:
  live_barcode_scanner: ^0.1.0
```

Run `flutter pub get` to install the package.

## Usage

### Basic Example

The `LiveBarcodeScannerWidget` provides a full-screen barcode scanner. Below is a simple example that displays scanned barcodes and handles errors:

```dart
import 'package:flutter/material.dart';
import 'package:live_barcode_scanner/live_barcode_scanner.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final controller = LiveBarcodeScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Barcode Scanner')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  controller.showBarCodeScanner(context, (result) {
                    debugPrint("Result: $result");
                  }, () {});
                },
                child: Text("Start"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

```

### Controlling the Scanner

The package provides a method channel to control the scanner:

- **Start Scanning**:
  ```dart
  await _methodChannel.invokeMethod('startScan', {'scanFrameSize': 300.0});
  ```

- **Stop Scanning**:
  ```dart
  await _methodChannel.invokeMethod('stopScan');
  ```

- **Pause Scanning**:
  ```dart
  await _methodChannel.invokeMethod('pauseScan');
  ```

- **Resume Scanning**:
  ```dart
  await _methodChannel.invokeMethod('resumeScan');
  ```

- **Toggle Torch**:
  ```dart
  await _methodChannel.invokeMethod('toggleTorch');
  ```

- **Set Zoom**:
  ```dart
  await _methodChannel.invokeMethod('setZoom', {'zoomFactor': 2.0});
  ```

### Customizing the Scan Frame

You can adjust the scan frame size by passing `scanFrameSize` in the `creationParams` or `startScan` call:

```dart
UiKitView(
  viewType: 'live_barcode_scanner_view',
  creationParams: {'scanFrameSize': 250.0},
  creationParamsCodec: const StandardMessageCodec(),
)
```

## Platform Configuration

### iOS

1. **Add Camera Permission**:
   Update your `ios/Runner/Info.plist` to include the camera usage description:

   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need camera access to scan barcodes.</string>
   ```

2. **Minimum iOS Version**:
   Ensure your `ios/Podfile` specifies at least iOS 13.0:

   ```ruby
   platform :ios, '13.0'
   ```

### Android

1. **Add Camera Permission**:
   Update your `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   ```

2. **Request Permission**:
   Ensure your app requests camera permission at runtime. For example, use the `permission_handler` package:

   ```dart
   import 'package:permission_handler/permission_handler.dart';

   Future<void> requestCameraPermission() async {
     var status = await Permission.camera.request();
     if (!status.isGranted) {
       // Handle permission denied
     }
   }
   ```

3. **Minimum SDK**:
   Ensure your `android/app/build.gradle` specifies at least API 21:

   ```gradle
   minSdkVersion 21
   ```

## Troubleshooting

- **Black Screen on iOS**:
  - Ensure the `UiKitView` is wrapped in a `Scaffold` or `SizedBox.expand` to provide a non-zero frame.
  - Check Xcode console logs for errors (e.g., `INVALID_FRAME`, `NO_CAMERA`).
  - Verify camera permissions are granted and `Info.plist` is configured.

- **Black Screen on Android**:
  - Confirm camera permissions are requested and granted.
  - Check Android logs in Android Studio for native errors.

- **No Barcodes Detected**:
  - Ensure the camera is focused and the barcode is within the scan frame.
  - Verify the barcode type is supported (see supported formats above).

- **Errors in Flutter UI**:
  - Check the event channel for error events (e.g., `PERMISSION_DENIED`, `SESSION_NOT_RUNNING`).
  - Review console logs for detailed error messages.

For detailed debugging, enable verbose logging in your app and check the native logs (Xcode for iOS, Logcat for Android).

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/my-feature`).
3. Commit your changes (`git commit -m 'Add my feature'`).
4. Push to the branch (`git push origin feature/my-feature`).
5. Open a pull request.

Please include tests and update the documentation as needed.

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

[Pub.dev](https://pub.dev) | [GitHub](https://github.com/your-repo/live_barcode_scanner) | [Issues](https://github.com/your-repo/live_barcode_scanner/issues)