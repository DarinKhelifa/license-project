import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:orelax/widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../providers/auth_provider.dart';
import '../../../providers/social_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedImageBytes = [];
  bool _isPosting = false;

  String? _resolveAvatarUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    return 'http://localhost:5001$value';
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();

    if (pickedFiles.isEmpty) return;

    final bytesList = await Future.wait(
      pickedFiles.map((file) => file.readAsBytes()),
    );

    if (!mounted) return;

    setState(() {
      _selectedImages.addAll(pickedFiles);
      _selectedImageBytes.addAll(bytesList);
    });
  }

  Future<void> _pickAttachments() async {
    // In a real app, use file_picker package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File picker - implement with file_picker package')),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _selectedImageBytes.removeAt(index);
    });
  }

  Future<void> _postContent() async {
    if (_contentController.text.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add some content!')),
      );
      return;
    }

    setState(() => _isPosting = true);

    final success = await context.read<SocialProvider>().createPost(
      content: _contentController.text,
      images: _selectedImages.isNotEmpty ? _selectedImageBytes : null,
      imageNames: _selectedImages.isNotEmpty ? _selectedImages.map((file) => file.name).toList() : null,
    );

    if (mounted) {
      setState(() => _isPosting = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post shared!'),
            backgroundColor: const Color(0xFF1A5C2A),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);
    const Color lightGreen = Color(0xFFE8F5E9);
    final authProvider = context.watch<AuthProvider>();
    final userName = (authProvider.userName ?? 'You').trim().isEmpty ? 'You' : authProvider.userName!.trim();
    final avatarUrl = _resolveAvatarUrl(authProvider.userAvatar);

    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        scrolledUnderElevation: 0,
        title: Text(
          'Create Post',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isPosting ? null : _postContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPosting ? Colors.grey : darkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isPosting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Post',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header - User info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: lightGreen,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? const Icon(Icons.person, color: darkGreen) : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Public',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Input
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                minLines: 5,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(0),
                ),
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),

            // Selected Images
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // Bottom Actions
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.image_outlined,
                        label: 'Photo/Video',
                        onTap: _pickImages,
                      ),
                      _buildActionButton(
                        icon: Icons.attach_file,
                        label: 'Attachment',
                        onTap: _pickAttachments,
                      ),
                      _buildActionButton(
                        icon: Icons.emoji_emotions_outlined,
                        label: 'Emoji',
                        onTap: () {
                          // Implement emoji picker
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        onTap: () {
                          // Implement location picker
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    const Color darkGreen = Color(0xFF1A5C2A);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: darkGreen, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
