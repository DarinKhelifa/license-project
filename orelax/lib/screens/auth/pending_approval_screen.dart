import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../services/api_service.dart';
import '../../widgets/auth_error_banner.dart';

class PendingApprovalScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String token;

  const PendingApprovalScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.token,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  Timer? _pollTimer;
  bool _isChecking = false;
  static const int _pollIntervalSeconds = 5;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(Duration(seconds: _pollIntervalSeconds), (_) {
      _checkApprovalStatus();
    });
  }

  Future<void> _checkApprovalStatus() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = (data['status'] ?? '').toString().toLowerCase();
        final isEmailVerified = data['isEmailVerified'] == true;

        if (isEmailVerified && status == 'active') {
          _pollTimer?.cancel();
          
          // Save token only after approval
          await ApiService.saveToken(widget.token);
          
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
      }
    } catch (e) {
      // Silent fail, will retry on next poll
    }

    setState(() => _isChecking = false);
  }

  Future<void> _logout() async {
    _pollTimer?.cancel();
    // Token was never saved, so no need to remove it
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF034808),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _logout,
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF034808).withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Color(0xFF034808),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Account Created Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF034808),
                  ),
                ),

                const SizedBox(height: 16),

                // Email Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Main Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF2D38A), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFE9B8),
                        ),
                        child: const Icon(
                          Icons.hourglass_top,
                          color: Color(0xFFB58100),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Waiting for Admin Approval',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7A5A00),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your account has been created and your email has been verified. An administrator is reviewing your account details.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7A5A00),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AuthErrorBanner(
                        message: 'You will be redirected automatically once your account is approved.',
                        variant: AuthBannerVariant.info,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Status Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isChecking
                            ? const Color(0xFFFFC107)
                            : const Color(0xFF034808),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF034808),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isChecking
                          ? 'Checking status...'
                          : 'Checking every ${_pollIntervalSeconds}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'What happens next?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• The admin will review your account information\n'
                        '• Once approved, you\'ll gain full access to your account\n'
                        '• This typically takes a few minutes to a few hours\n'
                        '• You can check back later or wait here',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Logout and Go Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF034808),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
