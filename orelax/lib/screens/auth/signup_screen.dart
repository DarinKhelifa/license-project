import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../Home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  final String? initialRole;
  const SignupScreen({super.key, this.initialRole});

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
  final _passwordController = TextEditingController();
  bool get _isResident => (widget.initialRole ?? 'resident').toString().trim().toLowerCase() == 'resident';
  // apartment selection is handled via `_selectedApartment` dropdown
  List<Map<String, dynamic>> _residences = [];
  String? _selectedResidenceId;
  String? _selectedBuildingId;
  String? _selectedApartment;
  bool _isResidencesLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadResidences();
  }

  Future<void> _loadResidences() async {
    setState(() => _isResidencesLoading = true);
    try {
      final list = await ApiService.getResidences();
      setState(() => _residences = list);
    } catch (_) {
      // ignore: avoid_print
      print('Failed to load residences');
    }
    setState(() => _isResidencesLoading = false);
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
    // Apartment/residence/building are only required for residents
    if (_isResident) {
      if (_selectedApartment == null || _selectedApartment!.trim().isEmpty) {
        _showError('Please select your apartment number');
        return;
      }
      if (_selectedResidenceId == null) {
        _showError('Please select your residence');
        return;
      }
      if (_selectedBuildingId == null) {
        _showError('Please select your building');
        return;
      }
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
      residence: _isResident ? _selectedResidenceId : null,
      building: _isResident ? _selectedBuildingId : null,
      apartment: _isResident ? _selectedApartment : null,
      phone: _phoneController.text.trim(),
      role: widget.initialRole ?? 'resident',
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
                          if (_isResident) ...[
                            // Apartment is selected after choosing residence and building
                            // Residence Dropdown (shows spinner while loading)
                            _isResidencesLoading
                                ? SizedBox(height: 56, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                                : (_residences.isEmpty
                                    ? const Text('No residences available', style: TextStyle(color: Colors.grey))
                                    : DropdownButtonFormField<String>(
                                        value: _selectedResidenceId,
                                        decoration: _decoration('select residence', Icons.home_outlined),
                                        items: _residences
                                            .map((r) => DropdownMenuItem(
                                                  value: (r['_id'] ?? r['id'] ?? r['name']).toString(),
                                                  child: Text(r['name'] ?? r['address'] ?? 'Residence'),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedResidenceId = val;
                                            _selectedBuildingId = null;
                                            _selectedApartment = null;
                                          });
                                        },
                                      )),
                            const SizedBox(height: 12),
                            // Building Dropdown
                            (_selectedResidenceId == null)
                                ? const SizedBox()
                                : DropdownButtonFormField<String>(
                                    value: _selectedBuildingId,
                                    decoration: _decoration('select building', Icons.apartment_outlined),
                                    items: (_residences.firstWhere((r) => (r['_id'] ?? r['id']).toString() == _selectedResidenceId,
                                          orElse: () => {})['buildings'] as List<dynamic>?)
                                        ?.map((b) => DropdownMenuItem(
                                              value: (b['id'] ?? b['name']).toString(),
                                              child: Text(b['name'] ?? b['id'] ?? 'Building'),
                                            ))
                                        .toList() ??
                                    [],
                                    onChanged: (val) => setState(() {
                                      _selectedBuildingId = val;
                                      _selectedApartment = null;
                                    }),
                                  ),
                            const SizedBox(height: 12),
                            // Apartment selection: show dropdown only if building selected
                            (_selectedBuildingId == null)
                                ? const SizedBox()
                                : DropdownButtonFormField<String>(
                                    value: _selectedApartment,
                                    decoration: _decoration('select apartment', Icons.home_work_outlined),
                                    items: (() {
                                      final resList = _residences
                                          .where((r) => (r['_id'] ?? r['id']).toString() == _selectedResidenceId)
                                          .toList();
                                      if (resList.isEmpty) return <DropdownMenuItem<String>>[];
                                      final res = resList.first;
                                      final buildings = (res['buildings'] as List<dynamic>?) ?? [];
                                      final bList = buildings
                                          .where((b) => (b['id'] ?? b['name']).toString() == _selectedBuildingId)
                                          .toList();
                                      if (bList.isEmpty) return <DropdownMenuItem<String>>[];
                                      final building = bList.first;
                                      final count = building['apartments'] is int
                                          ? building['apartments'] as int
                                          : int.tryParse(building['apartments']?.toString() ?? '') ?? 0;
                                      if (count <= 0) return <DropdownMenuItem<String>>[];
                                      return List.generate(count, (i) => (i + 1).toString().padLeft(2, '0'))
                                          .map((apt) => DropdownMenuItem(value: apt, child: Text(apt)))
                                          .toList();
                                    })(),
                                    onChanged: (val) => setState(() => _selectedApartment = val),
                                  ),
                          ],
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