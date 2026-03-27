import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../Home/home_screen.dart';
import '../onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthWrapper - isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}');
        
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF034808),
              ),
            ),
          );
        }
        
        if (authProvider.isAuthenticated) {
          print('User is authenticated, showing HomeScreen');
          return const HomeScreen();
        }
        
        print('User is not authenticated, showing OnboardingScreen');
        return const OnboardingScreen();
      },
    );
  }
}