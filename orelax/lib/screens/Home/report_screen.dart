import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../models/report_model.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _selectedCategoryKey;
  String? _selectedSubCategoryKey;

  // Location dropdown selections (any one optional, but at least one required)
  String? _selectedStreet;
  String? _selectedBlock;
  String? _selectedApartment;

  // Category definitions: backend keys -> display, color, icon, subcategories (display->key)
  final Map<String, Map<String, dynamic>> _categories = {
    'security': {
      'label': 'Security',
      'color': const Color(0xFFEF5350),
      'icon': Icons.shield_outlined,
      'subs': {
        'theft': 'Theft',
        'suspicious': 'Suspicious Activity',
        'assault': 'Assault',
      }
    },
    'maintenance': {
      'label': 'Maintenance',
      'color': const Color(0xFFFFA726),
      'icon': Icons.build_outlined,
      'subs': {
        'plumbing': 'Plumbing',
        'electrical': 'Electrical',
        'pest': 'Pest',
        'structural': 'Structural',
      }
    },
    'noise': {
      'label': 'Noise',
      'color': const Color(0xFF42A5F5),
      'icon': Icons.volume_up_outlined,
      'subs': {
        'loud_music': 'Loud Music',
        'party': 'Party',
        'construction': 'Construction',
      }
    },
    'other': {
      'label': 'Other',
      'color': const Color(0xFF9E9E9E),
      'icon': Icons.report_problem_outlined,
      'subs': {
        'other': 'Other',
      }
    },
  };
  bool _isTimeNow = true;
  TimeOfDay? _selectedTime;
  String? _photoBase64;
  bool _isPickingPhoto = false;
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // static lists for dropdowns
  final List<String> _streets = List.generate(10, (i) => 'Street ${i + 1}');
  final List<String> _blocks = List.generate(20, (i) => 'Block ${String.fromCharCode(65 + (i % 26))}${i + 1}');
  final List<String> _apartments = List.generate(20, (i) => 'Apt ${i + 1}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'REPORT INCIDENT',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. INCIDENT CATEGORY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category selection as colored icon cards
                          Row(
                            children: _categories.keys.map((key) {
                              final meta = _categories[key]!;
                              final label = meta['label'] as String;
                              final color = meta['color'] as Color;
                              final icon = meta['icon'] as IconData;
                              final selected = _selectedCategoryKey == key;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedCategoryKey = key;
                                    _selectedSubCategoryKey = null;
                                  }),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selected ? color : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: selected ? [BoxShadow(color: Colors.black12, blurRadius: 6)] : null,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: selected ? Colors.white24 : Colors.white,
                                          child: Icon(icon, color: selected ? Colors.white : Colors.black87),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: selected ? Colors.white : Colors.black87,
                                            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),

                          if (_selectedCategoryKey != null) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_categories[_selectedCategoryKey]!['subs'] as Map<String, String>)
                                  .entries
                                  .map((entry) {
                                final subKey = entry.key;
                                final subLabel = entry.value;
                                final chosen = _selectedSubCategoryKey == subKey;
                                return ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.label, size: 16, color: chosen ? Colors.white : Colors.black54),
                                      const SizedBox(width: 6),
                                      Text(subLabel, style: TextStyle(color: chosen ? Colors.white : Colors.black87)),
                                    ],
                                  ),
                                  selected: chosen,
                                  onSelected: (_) => setState(() => _selectedSubCategoryKey = subKey),
                                  selectedColor: (_categories[_selectedCategoryKey]!['color'] as Color),
                                  backgroundColor: Colors.grey[100],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    '2. INCIDENT DETAILS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location dropdowns (choose any one or multiple)
                          DropdownButtonFormField<String>(
                            value: _selectedStreet,
                            hint: const Text('None'),
                            decoration: InputDecoration(
                              labelText: 'Street (optional)',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            items: _streets.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _selectedStreet = v),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBlock,
                            hint: const Text('None'),
                            decoration: InputDecoration(
                              labelText: 'Block (optional)',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            items: _blocks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                            onChanged: (v) => setState(() => _selectedBlock = v),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedApartment,
                            hint: const Text('None'),
                            decoration: InputDecoration(
                              labelText: 'Apartment (optional)',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                            items: _apartments.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                            onChanged: (v) => setState(() => _selectedApartment = v),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Description (optional)',
                              hintText: 'Describe what happened...',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Buttons row - Add Photos / Time
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.photo_camera_outlined,
                    label: 'Add Photos',
                    onTap: _onAddPhotosTap,
                    hasPhoto: _photoBase64 != null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeButton(),
                ),
              ],
            ),

            if (_photoBase64 != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: MemoryImage(base64Decode(_photoBase64!)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => setState(() => _photoBase64 = null),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5C2A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SUBMIT REPORT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddPhotosTap() async {
    if (_isPickingPhoto) return;
    
    setState(() => _isPickingPhoto = true);
    
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _photoBase64 = base64Encode(bytes);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo added to report')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _onTimeButtonTap() async {
    final TimeOfDay initialTime = _selectedTime ?? TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (!mounted || picked == null) return;

    setState(() {
      _isTimeNow = false;
      _selectedTime = picked;
    });
  }

  Future<void> _submitReport() async {
    // Validate form fields (category, subcategory, location)
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showError('Please complete the required fields');
      return;
    }

    // ensure at least one location field is provided
    final street = _selectedStreet?.trim() ?? '';
    final block = _selectedBlock?.trim() ?? '';
    final apt = _selectedApartment?.trim() ?? '';
    if (street.isEmpty && block.isEmpty && apt.isEmpty) {
      _showError('Please provide at least one location (street, block, or apartment)');
      return;
    }

    if (_selectedCategoryKey == null || _selectedSubCategoryKey == null) {
      _showError('Please select a category and a subcategory');
      return;
    }

    setState(() {});

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      _showError('You must be logged in to submit a report');
      return;
    }

    final locationParts = <String>[];
    if (street.isNotEmpty) locationParts.add('Street: $street');
    if (block.isNotEmpty) locationParts.add('Block: $block');
    if (apt.isNotEmpty) locationParts.add('Apartment: $apt');

    final report = Report(
      id: '',
      category: _selectedCategoryKey!,
      subCategory: _selectedSubCategoryKey!,
      location: locationParts.join(' | '),
      description: _descriptionController.text.trim(),
      photoBase64: _photoBase64,
      timeIsNow: _isTimeNow,
      customTime: !_isTimeNow && _selectedTime != null 
          ? _selectedTime!.format(context) 
          : null,
      status: 'pending',
      createdBy: currentUser['id'] ?? '',
      createdByName: currentUser['name'] ?? 'User',
      createdAt: DateTime.now(),
    );

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final success = await reportProvider.createReport(report);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: Color(0xFF1A5C2A),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      _showError(reportProvider.error ?? 'Failed to submit report');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasPhoto = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: hasPhoto ? const Color(0xFF1A5C2A).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: hasPhoto ? const Color(0xFF1A5C2A) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 20, 
              color: hasPhoto ? const Color(0xFF1A5C2A) : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              hasPhoto ? 'Photo Added' : label,
              style: TextStyle(
                color: hasPhoto ? const Color(0xFF1A5C2A) : Colors.black87,
                fontSize: 14,
                fontWeight: hasPhoto ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    return GestureDetector(
      onTap: _onTimeButtonTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: _isTimeNow ? const Color(0xFF1A5C2A) : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              _isTimeNow
                  ? 'Time: Now'
                  : 'Time: ${_selectedTime != null ? _selectedTime!.format(context) : 'Select'}',
              style: TextStyle(
                color: _isTimeNow ? const Color(0xFF1A5C2A) : Colors.black87,
                fontSize: 14,
                fontWeight: _isTimeNow ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}