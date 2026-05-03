import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String userId;
  final String email;

  const OTPVerificationScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  void _startResendCooldown() {
    setState(() => _resendCountdown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        return true;
      }
      return false;
    });
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'otp': _otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await ApiService.saveToken(data['token']);
        if (mounted) {
          // Navigate to WelcomeScreen with navigateToHome flag to show animation then go to home
          Navigator.pushReplacementNamed(
            context,
            '/welcome',
            arguments: {'navigateToHome': true},
          );
        }
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Verification failed');
        if (data['expired'] == true) {
          for (var controller in _otpControllers) {
            controller.clear();
          }
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _startResendCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New verification code sent!')),
        );
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Failed to resend code');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF034808)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Verify Your Email',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF034808)),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to ${widget.email}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => SizedBox(
                width: 50,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  onChanged: (value) {
                    if (value.length == 1 && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                    if (_otp.length == 6) _verifyOTP();
                  },
                ),
              )),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF034808),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('VERIFY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: TextButton(
                onPressed: _resendCountdown > 0 || _isLoading ? null : _resendOTP,
                child: Text(
                  _resendCountdown > 0 
                      ? 'Resend code in ${_resendCountdown}s' 
                      : 'Resend code',
                  style: TextStyle(
                    color: _resendCountdown > 0 ? Colors.grey : const Color(0xFF034808),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}