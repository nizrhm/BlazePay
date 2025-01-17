import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solana_pay/main/paytocontact.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String address;
  final String amount;

  const TransactionDetailScreen({
    Key? key,
    required this.address,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circle Avatar at the top
              CircleAvatar(
                backgroundColor:
                    Colors.primaries[Random().nextInt(Colors.primaries.length)],
                radius: 40, // Adjusted radius for better visibility
                child: Text(
                  address[0]
                      .toUpperCase(), // Display the first letter of the address
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              const SizedBox(height: 20),

              // Address Text with Gesture Detector
              GestureDetector(
                onTap: () {
                  _copyToClipboard(address, context);
                },
                child: Text(
                  address,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),

              // Glassmorphic Button
              GestureDetector(
                onTap: () {
                  _goToPayToContactScreen(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.1), // Semi-transparent background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2), // Glass effect border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Pay Again',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              SizedBox(
                height: 70,
              ),
              Text(
                "Note: Copy the Address by clicking on the address.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String walletId, BuildContext context) {
    Clipboard.setData(ClipboardData(text: walletId)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address copied to clipboard!')),
      );
    });
  }

  void _goToPayToContactScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayToContactScreen(),
      ),
    );
  }
}
