import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:solana_pay/main/amountentry.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  bool scanned = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller and animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Repeats the animation
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF414B59),
      ),
      body: Stack(
        children: [
          // Mobile Scanner View
          MobileScanner(
            onDetect: (barcodeCapture) {
              final barcode = barcodeCapture.barcodes.first;
              if (barcode.rawValue != null && !scanned) {
                final String code = barcode.rawValue!;
                scanned = true;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AmountEntryScreen(walletAddress: code),
                  ),
                );
              }
            },
          ),

          // Scanning overlay animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CornerBoxPainter(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the box-shaped corner scanning animation
class CornerBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cornerLength = 40.0; // Length of the corner lines
    final double cornerWidth = 4.0; // Thickness of the corner lines
    final double padding = 20.0; // Padding from the edges of the screen

    final Paint paint = Paint()
      ..color = const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8)
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke;

    // Define the area for the scanning box (center of the screen)
    final Rect scanRect = Rect.fromLTWH(
      padding,
      size.height * 0.25, // Start scanning area 25% down the screen
      size.width - (2 * padding),
      size.height * 0.5, // Scanning box takes 50% of the screen height
    );

    // Draw the corner lines for the scanning box

    // Top-left corner
    canvas.drawLine(
        scanRect.topLeft, scanRect.topLeft + Offset(0, cornerLength), paint);
    canvas.drawLine(
        scanRect.topLeft, scanRect.topLeft + Offset(cornerLength, 0), paint);

    // Top-right corner
    canvas.drawLine(
        scanRect.topRight, scanRect.topRight + Offset(0, cornerLength), paint);
    canvas.drawLine(
        scanRect.topRight, scanRect.topRight + Offset(-cornerLength, 0), paint);

    // Bottom-left corner
    canvas.drawLine(scanRect.bottomLeft,
        scanRect.bottomLeft + Offset(0, -cornerLength), paint);
    canvas.drawLine(scanRect.bottomLeft,
        scanRect.bottomLeft + Offset(cornerLength, 0), paint);

    // Bottom-right corner
    canvas.drawLine(scanRect.bottomRight,
        scanRect.bottomRight + Offset(0, -cornerLength), paint);
    canvas.drawLine(scanRect.bottomRight,
        scanRect.bottomRight + Offset(-cornerLength, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
