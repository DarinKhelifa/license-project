import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:orelax/widgets/custom_bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'guest_qr_popup.dart';

class GuestQRFormScreen extends StatefulWidget {
  const GuestQRFormScreen({super.key});

  @override
  State<GuestQRFormScreen> createState() => _GuestQRFormScreenState();
}

class _GuestQRFormScreenState extends State<GuestQRFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  String? _activeDialog;
  bool _isButtonPressed = false;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  // ✅ Fixed API endpoint
  static const String _baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
  }

  Future<void> _selectDate(BuildContext context) async {
    setState(() => _activeDialog = 'date');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF034808),
            ),
          ),
          child: child!,
        );
      },
    );
    setState(() => _activeDialog = null);
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    setState(() => _activeDialog = 'time');
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF034808),
            ),
          ),
          child: child!,
        );
      },
    );
    setState(() => _activeDialog = null);
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _generateQR() async {
    // Validate name field
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the guest\'s name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validate date
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an arrival date'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validate time
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an arrival time'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get the current resident's ID from AuthProvider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userData = await auth.getUserData();
      final residentId = userData?['id'] ?? userData?['uid'] ?? userData?['_id'] ?? '';
      
      if (residentId.isEmpty) {
        throw Exception('User ID not found');
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final timeStr = _selectedTime!.format(context);
      final fullDateTime = '$dateStr at $timeStr';

      // Get host name (resident's name)
      final hostName = userData?['name'] ?? userData?['fullName'] ?? 'Resident';

      // Call the backend API
      final response = await http.post(
        Uri.parse('$_baseUrl/api/guests/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': '',
          'visitDate': fullDateTime,
          'host': hostName,
          'residentId': residentId,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 && data['success'] == true) {
        // Show the QR popup with the base64 image from backend
        showGuestQRPopup(
          context,
          data['qrCode'],           // base64 QR from backend
          data['guest']['name'],    // guest name
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to generate QR'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      print('Error generating QR: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Widget _buildShadowBox({required Widget child, required bool isFocused}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                )
              ]
            : [],
      ),
      child: child,
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: const Color(0xFFE8E8E8),
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Header Pill
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A472A),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'My Guest Pass',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Centered Instruction Text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Enter the information below to generate a temporary\nQR Access code for your guest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Name Field (Required)
                _buildShadowBox(
                  isFocused: _nameFocus.hasFocus,
                  child: TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    decoration: _buildInputDecoration('Guest Full name', Icons.person),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the guest\'s name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Phone Field (Optional)
                _buildShadowBox(
                  isFocused: _phoneFocus.hasFocus,
                  child: TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDecoration('Phone number (optional)', Icons.phone),
                  ),
                ),
                const SizedBox(height: 20),

                // Date Field
                _buildShadowBox(
                  isFocused: _activeDialog == 'date',
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(30),
                    child: InputDecorator(
                      decoration: _buildInputDecoration('Expected arrival date', Icons.calendar_today),
                      isEmpty: _selectedDate == null,
                      child: Text(
                        _selectedDate == null
                            ? ''
                            : DateFormat('MMMM dd, yyyy').format(_selectedDate!),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Field
                _buildShadowBox(
                  isFocused: _activeDialog == 'time',
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    borderRadius: BorderRadius.circular(30),
                    child: InputDecorator(
                      decoration: _buildInputDecoration('Expected arrival time', Icons.access_time),
                      isEmpty: _selectedTime == null,
                      child: Text(
                        _selectedTime == null
                            ? ''
                            : _selectedTime!.format(context),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Generate Button
                GestureDetector(
                  onTapDown: (_) => setState(() => _isButtonPressed = true),
                  onTapUp: (_) => setState(() => _isButtonPressed = false),
                  onTapCancel: () => setState(() => _isButtonPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _isButtonPressed 
                              ? const Color(0xFF1A472A).withOpacity(0.5) 
                              : Colors.black.withOpacity(0.15),
                          blurRadius: _isButtonPressed ? 20 : 10,
                          spreadRadius: _isButtonPressed ? 3 : 0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateQR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A472A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2),
                                SizedBox(width: 12),
                                Text(
                                  'Generate Access QR',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}