import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

// Import platform-specific libraries conditionally
import 'dart:io' as io;

import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _apartmentController;
  bool _isLoading = false;
  dynamic _selectedPhoto; // Can be File (native) or Uint8List (web)
  Uint8List? _selectedPhotoBytes; // For web display
  final ImagePicker _imagePicker = ImagePicker();

  final Color darkGreen = const Color(0xFF1A5C2A);
  final Color lightGreen = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData?['name'] ?? '');
    _phoneController = TextEditingController(text: widget.userData?['phone'] ?? '');
    _apartmentController = TextEditingController(text: widget.userData?['apartment'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (kIsWeb) {
          _selectedPhotoBytes = bytes;
        } else {
          _selectedPhoto = io.File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (kIsWeb) {
          _selectedPhotoBytes = bytes;
        } else {
          _selectedPhoto = io.File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Prepare data with optional photo
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'apartment': _apartmentController.text.trim(),
      };
      
      // Add photo if one was selected
      if (kIsWeb) {
        if (_selectedPhotoBytes != null) {
          updateData['photo'] = _selectedPhotoBytes as dynamic;
        }
      } else {
        if (_selectedPhoto != null) {
          updateData['photo'] = _selectedPhoto as dynamic;
        }
      }
      
      final success = await authProvider.updateUserData(updateData);

      setState(() => _isLoading = false);

      if (success && mounted) {
        _showSnackBar('Profile updated successfully!');
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, true);
        });
      } else if (mounted) {
        _showSnackBar(
          authProvider.errorMessage ?? 'Failed to update profile',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red.shade600 : darkGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPhotoDisplay() {
    if (kIsWeb) {
      // Web: use Image.memory for bytes
      if (_selectedPhotoBytes != null) {
        return ClipOval(
          child: Image.memory(
            _selectedPhotoBytes!,
            fit: BoxFit.cover,
          ),
        );
      }
    } else {
      // Native: use Image.file
      if (_selectedPhoto != null && _selectedPhoto is io.File) {
        return ClipOval(
          child: Image.file(
            _selectedPhoto as io.File,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    // Default: show icon if no photo selected
    return Icon(
      Icons.person_outline,
      size: 60,
      color: darkGreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Photo Upload Section
              Center(
                child: Column(
                  children: [
                    // Avatar or Photo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: lightGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: darkGreen,
                          width: 3,
                        ),
                      ),
                      child: _buildPhotoDisplay(),
                    ),
                    const SizedBox(height: 12),
                    // Photo Options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            'Gallery',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lightGreen,
                            foregroundColor: darkGreen,
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(
                            'Camera',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lightGreen,
                            foregroundColor: darkGreen,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Form Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
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
                        fillColor: Colors.grey.shade50,
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (v) => v?.isEmpty ?? true ? 'Name required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                        hintText: 'Enter your phone number',
                        prefixIcon: Icon(Icons.phone_outlined, color: darkGreen),
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
                        fillColor: Colors.grey.shade50,
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (v) => v?.isEmpty ?? true ? 'Phone number required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Apartment Field
                    TextFormField(
                      controller: _apartmentController,
                      decoration: InputDecoration(
                        labelText: 'Apartment',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                        hintText: 'Enter your apartment number',
                        prefixIcon: Icon(Icons.home_outlined, color: darkGreen),
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
                        fillColor: Colors.grey.shade50,
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (v) => v?.isEmpty ?? true ? 'Apartment required' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveChanges,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    'Save Changes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
