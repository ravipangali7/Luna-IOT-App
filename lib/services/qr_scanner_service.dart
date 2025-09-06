import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrScannerService {
  static Future<String?> scanQrCode(BuildContext context) async {
    // Request camera permission
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      Get.snackbar(
        'Camera permission is required to scan QR code',
        'Please grant camera permission to scan QR code',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
    // Use Completer to properly handle the async result
    final completer = Completer<String?>();

    await Get.to(
      () => QrScannerScreen(
        onQrCodeScanned: (value) {
          completer.complete(value);
        },
      ),
    );

    return await completer.future;
  }
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, required this.onQrCodeScanned});

  final Function(String) onQrCodeScanned;

  @override
  QrScannerScreenState createState() => QrScannerScreenState();
}

class QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? controller;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR/Barcode'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await controller?.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  widget.onQrCodeScanned(barcode.rawValue!);
                  Get.back();
                  return;
                }
              }
            },
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Position QR/Bar code within the frame',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
