import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _selectedCategory;
  String? _selectedSubCategory;
  bool _isTimeNow = true;
  TimeOfDay? _selectedTime;
  XFile? _selectedPhoto;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INCIDENT CATEGORY
            const Text(
              '1. INCIDENT CATEGORY',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Security / Maintenance Row
            Row(
              children: [
                Expanded(
                  child: _buildCategoryButton(
                    label: 'Security',
                    isSelected: _selectedCategory == 'Security',
                    onTap: () => setState(() => _selectedCategory = 'Security'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryButton(
                    label: 'Maintenance',
                    isSelected: _selectedCategory == 'Maintenance',
                    onTap: () => setState(() => _selectedCategory = 'Maintenance'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Noise / Other Row
            Row(
              children: [
                Expanded(
                  child: _buildSubCategoryButton(
                    label: 'Noise',
                    isSelected: _selectedSubCategory == 'Noise',
                    onTap: () => setState(() => _selectedSubCategory = 'Noise'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSubCategoryButton(
                    label: 'Other',
                    isSelected: _selectedSubCategory == 'Other',
                    onTap: () => setState(() => _selectedSubCategory = 'Other'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 2. INCIDENT DETAILS
            const Text(
              '2. INCIDENT DETAILS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Specific Location
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'Specific Location (e.g. Block B, Lobby)',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe what happened...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Buttons row - Add Photos / Time
            Row(
              children: [
                // Add Photos Button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.photo_camera_outlined,
                    label: 'Add Photos',
                    onTap: () {
                      // TODO: Implement photo picking
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Time Button
                Expanded(
                  child: _buildTimeButton(),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement submit functionality
                  // Validate and submit report
                  if (_selectedCategory != null && 
                      _selectedSubCategory != null && 
                      _locationController.text.isNotEmpty &&
                      _descriptionController.text.isNotEmpty) {
                    // Submit report
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted successfully'),
                        backgroundColor: Color(0xFF1A5C2A),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
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

  Future<void> _onAddPhotosTap() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedPhoto = picked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo added to report'),
      ),
    );
  }

  Widget _buildCategoryButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A5C2A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A5C2A) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A5C2A) : Colors.grey[400]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: label == 'Add Photos' ? _onAddPhotosTap : onTap,
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
            Icon(icon, size: 20, color: Colors.black87),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}