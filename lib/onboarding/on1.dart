import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solana_pay/phone_authentication/auth1.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Welcome to BPay!',
      icon: 'assets/on1.png',
      description: 'Experience seamless and secure transactions with Solana.',
    ),
    OnboardingData(
      title: 'Set Up Your Wallet',
      icon: 'assets/2.png',
      description:
          'Create a new Solana wallet or import an existing one to get started',
    ),
    OnboardingData(
      title: 'Secure Your Wallet',
      icon: 'assets/3.png',
      description:
          'Transfer Solana to your wallet from an exchange or another wallet to start making transactions.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundShapes(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: GradientPainter(_animationController),
          child: Container(),
        );
      },
    );
  }

  Widget _buildContent() {
    return Container(
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
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildPage(_onboardingData[index]);
                },
              ),
            ),
            _buildPageIndicator(),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SizedBox(
                  width: screenWidth * 0.5,
                  height: screenHeight * 0.3,
                  child: Image.asset(data.icon, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                data.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                data.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
          _onboardingData.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == index ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildButton('Previous', () {
            if (_currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }),
          _buildButton(
            _currentPage < _onboardingData.length - 1 ? 'Next' : 'Get Started',
            () {
              if (_currentPage < _onboardingData.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhoneAuthScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class OnboardingData {
  final String title;
  final String icon;
  final String description;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class GradientPainter extends CustomPainter {
  final Animation<double> animation;

  GradientPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    List<double> stops = [];
    for (int i = 0; i < 5; i++) {
      stops.add((animation.value + (i * 0.2)) % 1.0);
    }

    final Gradient gradient = LinearGradient(
      colors: [
        Colors.blue,
        Colors.purple,
        Colors.red,
        Colors.orange,
        Colors.yellow,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: stops,
    );

    final Paint paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(GradientPainter oldDelegate) => true;
}
