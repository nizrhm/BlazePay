import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:solana_pay/main/main1.dart';

class WalletSuccessScreen extends StatefulWidget {
  final String walletAddress;
  final String audioFilePath;

  const WalletSuccessScreen({
    Key? key,
    required this.walletAddress,
    required this.audioFilePath, // Pass the audio file path
  }) : super(key: key);

  @override
  _WalletSuccessScreenState createState() => _WalletSuccessScreenState();
}

class _WalletSuccessScreenState extends State<WalletSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late AudioPlayer _audioPlayer; // To play the audio
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    // Initialize audio player
    _audioPlayer = AudioPlayer();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Start animation
    _controller.forward();

    // Play audio after the animation completes
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showContent = true;
        });
        await _audioPlayer.setAsset(widget.audioFilePath); // Load the mp3 file
        _audioPlayer.play(); // Play the audio
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose(); // Dispose the audio player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 3),
            builder: (context, double value, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Color.lerp(Color(0xFF1E3A8A), Colors.black, value)!,
                      Color.lerp(Color(0xFF172554), Colors.black, value)!,
                      Color.lerp(Colors.black, Colors.black, value)!,
                    ],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedOpacity(
                opacity: _showContent ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Account Created Successfully!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Solana Wallet Address:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.walletAddress,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Continue to Home',
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
        ],
      ),
    );
  }
}
