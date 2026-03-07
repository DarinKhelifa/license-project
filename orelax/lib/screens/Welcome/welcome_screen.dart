import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();

    // Background floating balls continuous animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Logo entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoController.forward();

    // 5 Second Navigation Timeout
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // We pushReplacement to Onboarding, which routes to Login eventually 
        // Or if the app routes directly to '/login' or '/home', change this string:
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
      backgroundColor: const Color(0xFF1A5C2A), // Deep App Green
      body: Stack(
        children: [
          // ── Animated Background Blobs ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final val = _bgController.value * 2 * math.pi;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Blob 1: Top Right (Large slow circular orbit)
                  Positioned(
                    top: -50 + math.sin(val) * 60,
                    right: -50 + math.cos(val) * 80,
                    child: _buildBlob(250),
                  ),
                  // Blob 2: Middle Left (Figure-8 pattern)
                  Positioned(
                    top: size.height * 0.4 + math.sin(val * 2) * 50,
                    left: -80 + math.cos(val) * 70,
                    child: _buildBlob(200),
                  ),
                  // Blob 3: Bottom Right (Elliptical wide orbit)
                  Positioned(
                    bottom: -60 + math.cos(val) * 90,
                    right: size.width * 0.1 + math.sin(val) * 110,
                    child: _buildBlob(280),
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
                    // Home + Checkmark Stack
                    Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.home_filled,
                          size: 90,
                          color: Colors.white,
                        ),
                        Positioned(
                          bottom: 4,
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
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // ORELAX Title
                    const Text(
                      'ORELAX',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber, 
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'SMART · SAFE · COMFORTABLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  // Helper widget to draw the semi-transparent glowing balls
  Widget _buildBlob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF81C784).withOpacity(0.35),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF81C784).withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}