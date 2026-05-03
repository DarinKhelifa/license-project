import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../Home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _apartmentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    if (_apartmentController.text.trim().isEmpty) {
      _showError('Please enter your apartment number');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter a password');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUpWithEmail(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      apartment: _apartmentController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      final user = authProvider.user;
      final userId = user?['_id'] ?? user?['id'];
      final email = user?['email'];

      if (userId != null && email != null) {
        // Navigate to OTP verification screen
        Navigator.pushNamed(context, '/otp', arguments: {
          'userId': userId.toString(),
          'email': email.toString(),
        });
        return;
      }

      // Fallback: navigate to home if user data isn't available
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = authProvider.errorMessage;
      });
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = authProvider.errorMessage;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Loginbackground.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay
          Container(color: Colors.black.withOpacity(0.3)),

          // 3. Header Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 4. Centered Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // CONTINUOUS WRITING ANIMATION
                    const ContinuousTypingText(text: 'ORELAX'),
                    const Text(
                      'Create your own residency experience',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 30),

                    // 5. Signup Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(_errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13)),
                            ),

                          _field('full name', Icons.person_outline, controller: _nameController),
                          const SizedBox(height: 12),
                          _field('email address', Icons.email_outlined,
                              controller: _emailController, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 12),
                          _field('apartment number', Icons.location_city_outlined, controller: _apartmentController),
                          const SizedBox(height: 12),
                          _field('phone number', Icons.phone_android_outlined,
                              controller: _phoneController, keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),

                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: _decoration('password', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4C5E48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Sign Up',
                                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 15),

                          const Text("Or Sign up using", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 12),

                          // Google Icon with Fixed Implementation
                          _GoogleSignInButton(onTap: _handleGoogleSignUp),
                          
                          const SizedBox(height: 20),

                          // Footer Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text("Sign In",
                                    style: TextStyle(color: Color(0xFF4C5E48), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
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

  Widget _field(String hint, IconData icon, {TextInputType keyboardType = TextInputType.text, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(hint, icon),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white, size: 20),
      filled: true,
      fillColor: const Color(0xFF8DA089),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
    );
  }
}

// --- FIXED Google Sign In Button Class ---
class _GoogleSignInButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(
                  Icons.g_mobiledata,
                  size: 24,
                  color: Color(0xFF034808),
                ),
              ),
              const SizedBox(height: 4),
              Text('Gmail',
                  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CONTINUOUS WRITING ANIMATION ---
class ContinuousTypingText extends StatefulWidget {
  final String text;
  const ContinuousTypingText({super.key, required this.text});

  @override
  State<ContinuousTypingText> createState() => _ContinuousTypingTextState();
}

class _ContinuousTypingTextState extends State<ContinuousTypingText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        String visibleString = widget.text.substring(0, _characterCount.value);
        return Text(
          visibleString,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 4,
          ),
        );
      },
    );
  }
}