import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solana_pay/main/solana.dart';
import 'package:lottie/lottie.dart';

class BalanceDisplayScreen extends StatefulWidget {
  const BalanceDisplayScreen({Key? key}) : super(key: key);

  @override
  _BalanceDisplayScreenState createState() => _BalanceDisplayScreenState();
}

class _BalanceDisplayScreenState extends State<BalanceDisplayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _walletService = SolanaWalletService();
  String? _senderAddress;
  double? _balance;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _loadSenderAddress();
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

  Future<void> _loadBalance() async {
    if (_senderAddress == null) return;

    try {
      final balance = await _walletService.getBalance(_senderAddress!);
      setState(() {
        _balance = balance;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load balance: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildGlassMorphismButton(),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/2.png"),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Wallet Balance',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildBalanceDisplay(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : _balance != null
              ? Text(
                  '${_balance!.toStringAsFixed(4)} SOL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Text(
                  'Balance unavailable',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
    );
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
        onPressed: () {
          _showRequestSolanaBottomSheet();
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

  void _showRequestSolanaBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(0xFF172554),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        LottieBuilder.network(
                          "https://lottie.host/272f844f-079b-4577-910b-1b05d2547e8f/F77Bg7QarL.json",
                          width: 100,
                          height: 100,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Request Solana',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'You are about to request Solana tokens. This action will initiate an airdrop to your wallet.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _requestAirdrop();
                          },
                          child: Text('Confirm Request'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Color(0xFF172554),
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
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
      },
    );
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
}
