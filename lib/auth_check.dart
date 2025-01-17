import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:solana_pay/main/main1.dart';
import 'package:solana_pay/onboarding/on1.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _loading = true;
  bool _isNewUser = true;
  String? _phoneNumber;

  @override
  void initState() {
    FlutterNativeSplash.remove();
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phone_number');
      final isNewUser = prefs.getBool('is_new_user') ?? true;

      setState(() {
        _phoneNumber = phoneNumber;
        _isNewUser = isNewUser;
        _loading = false;
      });
    } catch (e) {
      print('Error checking user status: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isNewUser || _phoneNumber == null) {
      return const OnboardingScreen();
    }

    return PasswordScreen(phoneNumber: _phoneNumber!);
  }
}

class PasswordScreen extends StatefulWidget {
  final String phoneNumber;

  const PasswordScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isDisposed = false;

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
                  'Enter Password',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please enter your password',
                  style: const TextStyle(
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
                  onCompleted: (_) => _verifyPassword(),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _verifyPassword,
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
                            'Login',
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

  Future<void> _verifyPassword() async {
    if (_isDisposed) return;

    final password = _pinController.text;

    if (password.length != 4) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a 4-digit password'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!_isDisposed) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await Supabase.instance.client
          .from('profile')
          .select()
          .eq('phone_number', widget.phoneNumber)
          .single();

      if (_isDisposed) return;

      if (response != null && response['password'] == password) {
        // Password is correct, navigate to home screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      } else {
        throw Exception('Invalid password');
      }
    } catch (e) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pinController.dispose();
    super.dispose();
  }
}
