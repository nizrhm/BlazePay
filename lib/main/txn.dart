import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:solana_pay/main/main1.dart';

class TransactionSuccessScreen extends StatefulWidget {
  final double amount;
  final String recipientAddress;

  const TransactionSuccessScreen({
    Key? key,
    required this.amount,
    required this.recipientAddress,
  }) : super(key: key);

  @override
  _TransactionSuccessScreenState createState() =>
      _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends State<TransactionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  AudioPlayer? _audioPlayer;
  bool _isAudioLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer!.setAsset('assets/wallet.mp3');
      if (mounted) {
        setState(() {
          _isAudioLoaded = true;
        });
        _playSuccessSound();
      }
    } catch (e) {
      print('Error loading audio: $e');
    }
  }

  Future<void> _playSuccessSound() async {
    if (_isAudioLoaded && _audioPlayer != null) {
      try {
        await _audioPlayer!.play();
      } catch (e) {
        print('Error playing audio: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                      Color(0xFF414B59), Color(0xFF121928), _controller.value)!,
                  Color.lerp(
                      Color(0xFF414B59), Colors.black, _controller.value)!,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Transaction Successful!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTransactionDetails(),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(),
                            ));
                      },
                      child: const Text('Back to Wallet'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildDetailRow('Amount', '${widget.amount} SOL'),
          const SizedBox(height: 10),
          _buildDetailRow(
              'Recipient', _truncateAddress(widget.recipientAddress)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 13) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
