import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart'; // ✅ only this is needed

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
      home: const OnboardingScreen(), // ✅ starts from onboarding
    );
  }
}
