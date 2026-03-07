import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();

    // Background floating balls
    _bgController = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    // Center logo animation
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoController.forward();

    // Auto navigate after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // Dark green background
      body: Stack(
        children: [
          // ── Background Floating Balls ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final value = _bgController.value;
              final val2pi = value * 2 * math.pi;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Ball 1: top-right area, radius 120, moves with sin
                  Positioned(
                    top: size.height * 0.1 + math.sin(val2pi) * 30,
                    right: size.width * 0.1 + math.cos(val2pi) * 30,
                    child: _buildBall(120),
                  ),
                  // Ball 2: middle-left area, radius 100, moves with cos
                  Positioned(
                    top: size.height * 0.5 + math.cos(val2pi) * 40,
                    left: size.width * 0.05 + math.sin(val2pi) * 40,
                    child: _buildBall(100),
                  ),
                  // Ball 3: bottom-right area, radius 140, moves with sin(val+1)
                  Positioned(
                    bottom: size.height * 0.1 + math.sin(val2pi + 1) * 50,
                    right: size.width * 0.05 + math.cos(val2pi + 1) * 50,
                    child: _buildBall(140),
                  ),
                ],
              );
            },
          ),

          // ── Center Content ──
          Center(
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Home icon with check mark badge
                    Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 60,
                        ),
                        Positioned(
                          bottom: 0,
                          right: -4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.amber,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ORELAX',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700), // Gold
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SMART · SAFE · COMFORTABLE',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        letterSpacing: 2.5,
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

  Widget _buildBall(double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
