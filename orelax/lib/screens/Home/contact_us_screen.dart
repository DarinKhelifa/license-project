import 'package:flutter/material.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  final Color darkGreen = const Color(0xFF1A5C2A);
  final Color lightGreen = const Color(0xFFE8F5E9);

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: <String, String>{
        'subject': 'Contact from ORELAX',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch email: $e')),
      );
    }
  }

  Future<void> _callPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone: $e')),
      );
    }
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: isSuccess ? darkGreen : Colors.red.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Contact Us',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.contact_support_outlined,
                      size: 50,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'re Here to Help',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get in touch with our support team',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contact Cards
            Text(
              'Quick Contact',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Admin Contact Card
            _buildContactCard(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin Support',
              email: 'orelax.admin@gmail.com',
              phone: '05562436215',
              onEmailTap: () => _sendEmail('orelax.admin@gmail.com'),
              onPhoneTap: () => _callPhone('05562436215'),
            ),

            const SizedBox(height: 12),

            // Security Contact Card
            _buildContactCard(
              icon: Icons.security_outlined,
              title: 'Security Team',
              email: 'kld060273@gmail.com',
              phone: '0798965312',
              onEmailTap: () => _sendEmail('kld060273@gmail.com'),
              onPhoneTap: () => _callPhone('0798965312'),
            ),

            const SizedBox(height: 32),

            // Send Message Section
            Text(
              'Send us a Message',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline, color: darkGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: darkGreen, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.poppins(),
            ),

            const SizedBox(height: 12),

            // Email Field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Your Email',
                labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                hintText: 'Enter your email address',
                prefixIcon: Icon(Icons.email_outlined, color: darkGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: darkGreen, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(),
            ),

            const SizedBox(height: 12),

            // Message Field
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                hintText: 'Tell us how we can help...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: darkGreen, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.poppins(),
            ),

            const SizedBox(height: 20),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _submitMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.send_outlined, color: Colors.white),
                label: Text(
                  _isSending ? 'Sending...' : 'Send Message',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: darkGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: darkGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We typically respond within 24 hours',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: darkGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String email,
    required String phone,
    required VoidCallback onEmailTap,
    required VoidCallback onPhoneTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: darkGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Email
          GestureDetector(
            onTap: onEmailTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined,
                      color: darkGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: darkGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.grey.shade400, size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Phone
          GestureDetector(
            onTap: onPhoneTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_outlined,
                      color: darkGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phone,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: darkGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.grey.shade400, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitMessage() async {
    if (_emailController.text.isEmpty || _messageController.text.isEmpty) {
      _showSnackBar('Please fill name, email and message', isSuccess: false);
      return;
    }

    setState(() => _isSending = true);

    final payload = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': '',
      'subject': 'Contact from app',
      'message': _messageController.text.trim(),
    };

    try {
      String host;
      if (kIsWeb) {
        host = Uri.base.host;
        if (host.isEmpty) host = 'localhost';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        host = '10.0.2.2';
      } else {
        host = 'localhost';
      }
      final uri = Uri.parse('http://$host:5000/api/contacts');
      final response = await httpPostJson(uri, payload);
      if (response != null && response['error'] == null) {
        _showSnackBar('Message sent successfully!');
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      } else {
        final err = response?['error'] ?? 'Unknown error';
        _showSnackBar('Failed to send message: $err', isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Failed to send message: ${e.toString()}', isSuccess: false);
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<Map<String, dynamic>?> httpPostJson(Uri uri, Map body) async {
    final client = http.Client();
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      final status = response.statusCode;
      if (status == 201 || status == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // Try to decode body for error details
      try {
        final decoded = jsonDecode(response.body);
        return {'error': decoded};
      } catch (_) {
        return {'error': 'Status $status'};
      }
    } on Exception catch (e) {
      return {'error': e.toString()};
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
