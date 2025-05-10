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
