import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:solana_pay/main/qrscreen.dart';

class QrScreen extends StatelessWidget {
  final String walletAddress;
  final GlobalKey _qrKey = GlobalKey();

  QrScreen({Key? key, required this.walletAddress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF414B59),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.download,
              color: Colors.white,
            ),
            onPressed: () async {
              await _requestPermission(context);
              _downloadQrCode(context);
            },
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF414B59),
            Color(0xFF121928),
            Color(0xFF101726),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          RepaintBoundary(
            key: _qrKey,
            child: _buildQrContainer(),
          ),
          const SizedBox(height: 10),
          Text(
            "Scan QR to pay using Solana",
            style: TextStyle(color: Colors.white, fontSize: 9),
          ),
          const Spacer(),
          _buildButtonRow(context),
        ],
      ),
    );
  }

  Widget _buildQrContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: QrImageView(
        data: walletAddress,
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildButtonRow(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton(context, 'Send QR Code', Icons.send),
          _buildButton(context, 'Open Scanner', Icons.qr_code_scanner),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (text == 'Send QR Code') {
          _shareQrCode(
              context); // Share QR code when 'Send QR Code' button is clicked
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QRScannerScreen(),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareQrCode(BuildContext context) async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save the image temporarily
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Share the image using share_plus
      await Share.shareXFiles([XFile(filePath)],
          text: 'Paying using solana in my wallet.');
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sharing QR Code: $e")),
      );
    }
  }

  Future<void> _downloadQrCode(BuildContext context) async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final result = await SaverGallery.saveImage(
        pngBytes,
        name: "${DateTime.now().millisecondsSinceEpoch}.png",
        androidExistNotSave: false,
      );

      if (result != null && result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("QR Code saved to gallery")),
        );
      } else {
        throw Exception("Failed to save image");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving QR Code: $e")),
      );
    }
  }
}

Future<void> _requestPermission(BuildContext context) async {
  if (Platform.isAndroid) {
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted");
    } else if (await Permission.manageExternalStorage.request().isGranted) {
      print("Manage external storage permission granted");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Storage permission denied")),
      );
    }
  }
}
