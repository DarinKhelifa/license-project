import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/Home/home-screen.dart';
import 'screens/Home/profile_screen.dart';
import 'screens/chat/chat_screen.dart';

void main() {
  runApp(const OrelaxApp());
}

class OrelaxApp extends StatelessWidget {
  const OrelaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ORELAX',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/chat': (context) => const ChatScreen(),
        //'/feed': (context) => const FeedScreen(),
      },
    );
  }
}
