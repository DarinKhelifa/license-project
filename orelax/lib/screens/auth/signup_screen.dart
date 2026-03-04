import 'package:flutter/material.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Green curved header
          ClipPath(
            clipper: _CurveClipper(),
            child: Container(height: 180, color: const Color(0xFF2E7D32)),
          ),

          // Circle below curve
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFF2E7D32), width: 2.5),
              ),
            ),
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back to login
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, size: 18),
                        SizedBox(width: 4),
                        Text('Back to login', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Sign Up', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  _field('Full Name', Icons.person_outline),
                  const SizedBox(height: 14),
                  _field('Phone / E-mail', Icons.phone_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _field('Home Address', Icons.location_on_outlined),
                  const SizedBox(height: 14),

                  // Password field (separate because of eye icon)
                  TextField(
                    obscureText: _obscurePassword,
                    decoration: _decoration('Password', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey.shade400, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign Up button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign In link
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.grey.shade500),
                          children: const [
                            TextSpan(text: 'Sign In', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable text field
  Widget _field(String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(keyboardType: keyboardType, decoration: _decoration(hint, icon));
  }

  // Reusable decoration
  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
    );
  }

  void _onSignUp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registration Successful!'),
        content: const Text('Welcome! Your account is under review and you\'ll receive a confirmation soon.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }
}

// Curved top clipper
class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(size.width / 2, size.height + 20, size.width, size.height - 40)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_CurveClipper oldClipper) => false;
}