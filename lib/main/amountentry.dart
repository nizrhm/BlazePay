import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solana_pay/main/paytocontact.dart';
import 'dart:math';

class AmountEntryScreen extends StatefulWidget {
  final String walletAddress;

  AmountEntryScreen({required this.walletAddress});

  @override
  _AmountEntryScreenState createState() => _AmountEntryScreenState();
}

class _AmountEntryScreenState extends State<AmountEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  // Function to generate a random alphabet
  String getRandomAlphabet() {
    const alphabets = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return alphabets[Random().nextInt(alphabets.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF1E3A8A),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF172554),
                  Colors.black,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circle avatar with random alphabet
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      getRandomAlphabet(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Recipient Address
                  Text(
                    'Recipient Address:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    widget.walletAddress,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),

                  // Center the TextField without an outline
                  Center(
                    child: SizedBox(
                      width: 300, // Adjust the width as per your design
                      child: TextFormField(
                        controller: _amountController,
                        style: TextStyle(color: Colors.white),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (SOL)',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none, // Removes the outline
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Centered Button with Glassmorphism
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Glass effect
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PayToContactScreen(
                                initialRecipientAddress: widget.walletAddress,
                                initialAmount:
                                    double.parse(_amountController.text),
                              ),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.transparent, // Transparent for glass effect
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
