import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:solana_pay/main/qr.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phone_number');

      if (phoneNumber == null) {
        throw Exception('Phone number not found in SharedPreferences');
      }

      final response = await Supabase.instance.client
          .from('profile')
          .select()
          .eq('phone_number', phoneNumber)
          .single();

      setState(() {
        _profileData = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        _profileData = null;
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String walletId) {
    Clipboard.setData(ClipboardData(text: walletId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet ID copied to clipboard!')),
    );
  }

  void _openQrScreen() {
    if (_profileData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              QrScreen(walletAddress: _profileData!['wallet_address']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF414B59),
        elevation: 0,
      ),
      body: Container(
        height: double.infinity, // Full screen height
        width: double.infinity, // Full screen width
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _profileData == null
                ? const Center(
                    child: Text('No profile data found',
                        style: TextStyle(color: Colors.white)))
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.25,
                                  height:
                                      MediaQuery.of(context).size.width * 0.25,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _profileData?['profile_image'] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            _profileData!['profile_image'],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset("assets/cool.png")),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _openQrScreen,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(0),
                                        bottomRight: Radius.circular(12),
                                        bottomLeft: Radius.circular(0)),
                                    child: QrImageView(
                                      data:
                                          _profileData!['wallet_address'] ?? '',
                                      version: QrVersions.auto,
                                      size: 40.0,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _profileData?['phone_number'] ?? 'No phone number',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_profileData?['wallet_address'] != null)
                            GestureDetector(
                              onTap: () => _copyToClipboard(
                                  _profileData!['wallet_address']),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Wallet ID: ${_profileData!['wallet_address'].substring(0, 6)}...${_profileData!['wallet_address'].substring(_profileData!['wallet_address'].length - 4)}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.copy,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Add settings and QR options
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildOptionRow(
                                icon: Icons.qr_code,
                                text: 'Your QR Code',
                                tetx2: 'Use to receive crypto',
                                onTap: _openQrScreen,
                              ),
                              const SizedBox(height: 16),
                              _buildPinSetupSection()
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // Helper method for building option rows
  Widget _buildOptionRow(
      {required IconData icon,
      required String text,
      required String tetx2,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                tetx2,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinSetupSection() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final prefs = snapshot.data!;
        final currentPinLength = prefs.getInt('pin_length');

        // If no PIN is set, show both options
        if (currentPinLength == null) {
          return Column(
            children: [
              _buildOptionRow(
                icon: Icons.pin,
                text: 'Set 4-Digit PIN',
                tetx2: 'For payment security',
                onTap: () => _showPinSetupDialog(4),
              ),
              const SizedBox(height: 16),
              _buildOptionRow(
                icon: Icons.pin,
                text: 'Set 6-Digit PIN',
                tetx2: 'Enhanced security',
                onTap: () => _showPinSetupDialog(6),
              ),
            ],
          );
        }

        // Show option to change existing PIN
        return _buildOptionRow(
          icon: Icons.pin,
          text: 'Change ${currentPinLength}-Digit PIN',
          tetx2: 'Update your security PIN',
          onTap: () => _showPinSetupDialog(currentPinLength),
        );
      },
    );
  }

  void _showPinSetupDialog(int pinLength) {
    String pin = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                    'Set ${pinLength}-Digit PIN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                    onChanged: (value) {
                      pin = value;
                    },
                    onCompleted: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('payment_pin', value);
                      await prefs.setInt('pin_length', pinLength);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PIN set successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
