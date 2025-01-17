import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:solana_pay/main/solana.dart';
import 'package:solana_pay/phone_authentication/wallet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordCreationScreen extends StatefulWidget {
  final String phoneNumber;

  const PasswordCreationScreen({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<PasswordCreationScreen> createState() => _PasswordCreationScreenState();
}

class _PasswordCreationScreenState extends State<PasswordCreationScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  final _walletService = SolanaWalletService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Password',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter a 4-digit password to secure your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                PinCodeTextField(
                  appContext: context,
                  length: 4,
                  obscureText: true,
                  obscuringCharacter: '*',
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(6),
                    fieldHeight: 60,
                    fieldWidth: 60,
                    activeFillColor: Colors.transparent,
                    inactiveFillColor: Colors.transparent,
                    selectedFillColor: Colors.transparent,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    selectedColor: Colors.white,
                  ),
                  cursorColor: Colors.white,
                  animationDuration: const Duration(milliseconds: 300),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 20),
                  backgroundColor: Colors.transparent,
                  enableActiveFill: true,
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  onCompleted: (_) => _createPassword(),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _createPassword,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createPassword() async {
    final password = _pinController.text;

    if (password.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 4-digit password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Check if phone number already exists
      final response = await supabase
          .from('profile')
          .select()
          .eq('phone_number', widget.phoneNumber)
          .maybeSingle();

      if (response != null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'This phone number is already registered. Please use a different number.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create Solana wallet
      final walletData = await _walletService.createWallet(widget.phoneNumber);

      // Save user data including wallet address
      await supabase.from('profile').upsert({
        'phone_number': widget.phoneNumber,
        'password': password,
        'verified': true,
        'wallet_address': walletData.publicKey,
      });

      // Save user status and wallet address in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_number', widget.phoneNumber);
      await prefs.setBool('is_new_user', false);
      await prefs.setString('wallet_address', walletData.publicKey);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WalletSuccessScreen(
              walletAddress: walletData.publicKey,
              audioFilePath: 'assets/wallet.mp3',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
