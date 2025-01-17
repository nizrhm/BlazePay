import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:solana_pay/main/solana.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solana_pay/main/txn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

class TwilioConfig {
  static const String accountSid = 'AC8ff1cb55656c5cd713292db3eebd828d';
  static const String authToken = '3e7007eb32e423373e7aeb3485cac39a';
  static const String twilioNumber = '+19893037890';
}

class PayToContactScreen extends StatefulWidget {
  final String? initialRecipientAddress;
  final double? initialAmount;
  const PayToContactScreen({
    Key? key,
    this.initialRecipientAddress,
    this.initialAmount,
  }) : super(key: key);

  @override
  State<PayToContactScreen> createState() => _PayToContactScreenState();
}

class _PayToContactScreenState extends State<PayToContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _walletService = SolanaWalletService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _senderAddress;
  double? _balance;
  final _supabase = Supabase.instance.client;
  late TwilioFlutter twilioFlutter;
  @override
  void initState() {
    super.initState();
    _loadSenderAddress();
    if (widget.initialRecipientAddress != null) {
      _recipientController.text = widget.initialRecipientAddress!;
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toString();
    }
    twilioFlutter = TwilioFlutter(
      accountSid: TwilioConfig.accountSid,
      authToken: TwilioConfig.authToken,
      twilioNumber: TwilioConfig.twilioNumber,
    );
  }

  Future<void> _loadSenderAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _senderAddress = prefs.getString('wallet_address');
    });
    if (_senderAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet address not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      _loadBalance();
    }
  }

  Future<bool> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('payment_pin');
    final pinLength = prefs.getInt('pin_length') ?? 4;

    if (savedPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please set up a PIN in your profile first')),
      );
      return false;
    }

    bool isPinCorrect = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        title: Text('Enter PIN to Confirm Payment',
            style: TextStyle(color: Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PinCodeTextField(
              appContext: context,
              length: pinLength,
              obscureText: true,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.white,
              ),
              onCompleted: (enteredPin) {
                isPinCorrect = enteredPin == savedPin;
                Navigator.pop(context);
              },
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );

    return isPinCorrect;
  }

  Future<void> _loadBalance() async {
    if (_senderAddress == null) return;

    try {
      final balance = await _walletService.getBalance(_senderAddress!);
      setState(() {
        _balance = balance;
      });
    } catch (e) {
      print('Failed to load balance: $e');
    }
  }

  Future<void> _requestAirdrop() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_senderAddress == null) {
        throw Exception('Sender address not found');
      }

      final signature = await _walletService.requestAirdrop(_senderAddress!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Airdrop received! Signature: ${signature.substring(0, 10)}...'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadBalance();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to request airdrop: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final recipientAddress = _recipientController.text;
    final amount = double.parse(_amountController.text);

    if (_senderAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sender address not found.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/txn.webp',
                      height: 100), // Placeholder image
                  const SizedBox(height: 20),
                  // Glassmorphic Container for Amount and Address
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Row for Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount:',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$amount SOL',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // Spacing
                        // Row for Recipient Address
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'To:',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                recipientAddress,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                textAlign:
                                    TextAlign.end, // Align the text to the end
                                overflow: TextOverflow
                                    .ellipsis, // Handle long addresses
                                maxLines: 1, // Limit to one line
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Cancel button
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(0, 255, 193, 7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close the bottom sheet
                          _performTransaction(recipientAddress, amount);
                        },
                        child: const Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _performTransaction(
      String recipientAddress, double amount) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_senderAddress == null) {
      setState(() {
        _errorMessage = 'Sender address not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    try {
      // PIN Verification
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('payment_pin');
      final pinLength = prefs.getInt('pin_length') ?? 4;

      if (savedPin == null) {
        throw Exception('Please set up a PIN in your profile first');
      }

      bool isPinCorrect = false;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        'Enter PIN to Confirm Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sending $amount SOL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      PinCodeTextField(
                        appContext: context,
                        length: pinLength,
                        obscureText: true,
                        animationType: AnimationType.fade,
                        keyboardType: TextInputType.number,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 50,
                          fieldWidth: 40,
                          activeFillColor: Colors.white.withOpacity(0.1),
                          selectedFillColor: Colors.white.withOpacity(0.1),
                          inactiveFillColor: Colors.white.withOpacity(0.1),
                          activeColor: Colors.white,
                          selectedColor: Colors.white,
                          inactiveColor: Colors.white.withOpacity(0.5),
                        ),
                        enableActiveFill: true,
                        onCompleted: (enteredPin) {
                          isPinCorrect = enteredPin == savedPin;
                          Navigator.pop(context);
                        },
                        onChanged: (value) {},
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      if (!isPinCorrect) {
        throw Exception('Incorrect PIN. Transaction cancelled.');
      }

      // Proceed with transaction if PIN is correct
      final signature = await _walletService.sendSol(
        senderAddress: _senderAddress!,
        recipientAddress: recipientAddress,
        amount: amount,
      );

      // Fetch sender's phone number
      final senderProfileResponse = await _supabase
          .from('profile')
          .select('phone_number')
          .eq('wallet_address', _senderAddress!)
          .maybeSingle();

      String? senderPhoneNumber =
          senderProfileResponse?['phone_number'] as String?;

      // Fetch recipient's phone number
      final recipientProfileResponse = await _supabase
          .from('profile')
          .select('phone_number')
          .eq('wallet_address', recipientAddress)
          .maybeSingle();

      String? recipientPhoneNumber =
          recipientProfileResponse?['phone_number'] as String?;

      // Send SMS notifications
      if (recipientPhoneNumber != null) {
        await sendSMS(
          recipientPhoneNumber,
          'You have received $amount SOL from ${_senderAddress!.substring(0, 10)}...',
        );
      }

      // Update transaction history
      if (senderPhoneNumber != null) {
        final existingEntry = await _supabase
            .from('history')
            .select()
            .eq('phon_number', senderPhoneNumber)
            .maybeSingle();

        if (existingEntry != null) {
          List<String> transactions =
              List<String>.from(existingEntry['transactions'] ?? []);
          List<String> amounts =
              List<String>.from(existingEntry['amounts'] ?? []);

          transactions.add(recipientAddress);
          amounts.add(amount.toString());

          await _supabase
              .from('history')
              .update({'transactions': transactions, 'amounts': amounts}).eq(
                  'phon_number', senderPhoneNumber);
        } else {
          await _supabase.from('history').insert({
            'phon_number': senderPhoneNumber,
            'transactions': [recipientAddress],
            'amounts': [amount.toString()],
          });
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionSuccessScreen(
              amount: amount,
              recipientAddress: recipientAddress,
            ),
          ),
        );
      }

      await _loadBalance();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildGlassMorphismButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextButton(
        onPressed: () async {
          await _requestAirdrop();
        },
        child: const Text(
          'Request Solana',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> sendSMS(String phoneNumber, String message) async {
    try {
      final response = await twilioFlutter.sendSMS(
        toNumber: phoneNumber,
        messageBody: message,
      );
      print('SMS sent successfully: $response');
    } catch (e) {
      print('Failed to send SMS: $e');
      // You might want to handle this error, perhaps by showing a snackbar to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SMS notification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildGlassMorphismButton(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
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
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_balance != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildBalanceInfo(),
                        ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _recipientController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/add.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          labelText: 'Recipient Wallet Address',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.white70, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter recipient wallet address';
                          }
                          if (!_walletService.isValidSolanaAddress(value)) {
                            return 'Please enter a valid Solana address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _amountController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/add2.webp',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          labelText: 'Amount (SOL)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.white70, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.all(20), // Adjust bottom padding as needed
                child: FractionallySizedBox(
                  widthFactor: 0.99, // 65% width of the screen
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.2), // Glassmorphism effect
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors
                                .transparent, // Transparent background for glassmorphism
                            shadowColor: Colors
                                .transparent, // Remove default button shadow
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Send Payment',
                            style: TextStyle(color: Colors.white, fontSize: 18),
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
      ),
    );
  }

  Container _buildBalanceInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Glassmorphism effect
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,

            backgroundImage:
                AssetImage('assets/bank.png'), // Use backgroundImage property
          ),
          const SizedBox(width: 16), // Space between image and text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Balance:',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right, // Align the text to the right
                ),
                Text(
                  "${_balance!.toStringAsFixed(4)} SOL",
                  style: TextStyle(color: Colors.grey),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
