import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/facility_model.dart';
import '../../../providers/facility_provider.dart';

class CreateEditFacilityScreen extends StatefulWidget {
  final Facility? facility;

  const CreateEditFacilityScreen({super.key, this.facility});

  @override
  State<CreateEditFacilityScreen> createState() => _CreateEditFacilityScreenState();
}

class _CreateEditFacilityScreenState extends State<CreateEditFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _hoursController = TextEditingController();
  final _priceController = TextEditingController();
  
  List<String> _imagesBase64 = [];
  List<String> _features = [];
  List<String> _rules = [];
  
  final TextEditingController _featureController = TextEditingController();
  final TextEditingController _ruleController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPickingImages = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.facility != null) {
      _loadFacilityData();
    }
  }

  void _loadFacilityData() {
    _nameController.text = widget.facility!.name;
    _descriptionController.text = widget.facility!.description;
    _capacityController.text = widget.facility!.capacity.toString();
    _hoursController.text = widget.facility!.hours;
    _priceController.text = widget.facility!.pricePerHour.toString();
    _imagesBase64 = List.from(widget.facility!.imagesBase64);
    _features = List.from(widget.facility!.features);
    _rules = List.from(widget.facility!.rules);
  }

  Future<void> _pickImages() async {
    if (_isPickingImages) return;
    
    setState(() => _isPickingImages = true);
    
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing ${images.length} image(s)...'),
            duration: const Duration(seconds: 1),
          ),
        );
        
        final List<String> newImages = [];
        
        for (int i = 0; i < images.length; i++) {
          try {
            final XFile image = images[i];
            final bytes = await image.readAsBytes();
            final base64String = base64Encode(bytes);
            newImages.add(base64String);
            print('Successfully added image ${i + 1}/${images.length}');
          } catch (e) {
            print('Error processing image ${i + 1}: $e');
          }
        }
        
        if (newImages.isNotEmpty && mounted) {
          setState(() {
            _imagesBase64.addAll(newImages);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${newImages.length} image(s) successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick images. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagesBase64.removeAt(index);
    });
  }

  void _addFeature() {
    if (_featureController.text.trim().isNotEmpty) {
      setState(() {
        _features.add(_featureController.text.trim());
        _featureController.clear();
      });
    }
  }

  void _removeFeature(int index) {
    setState(() {
      _features.removeAt(index);
    });
  }

  void _addRule() {
    if (_ruleController.text.trim().isNotEmpty) {
      setState(() {
        _rules.add(_ruleController.text.trim());
        _ruleController.clear();
      });
    }
  }

  void _removeRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
  }

  Future<void> _saveFacility() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imagesBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final facilityProvider = Provider.of<FacilityProvider>(context, listen: false);
      
      // Parse with error handling
      int capacity;
      double price;
      
      try {
        capacity = int.parse(_capacityController.text.trim());
      } catch (e) {
        throw Exception('Capacity must be a valid number');
      }
      
      try {
        price = double.parse(_priceController.text.trim());
      } catch (e) {
        throw Exception('Price must be a valid number');
      }
      
      final facility = Facility(
        id: widget.facility?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        capacity: capacity,
        hours: _hoursController.text.trim(),
        imagesBase64: _imagesBase64,
        features: _features,
        rules: _rules,
        pricePerHour: price,
        createdAt: widget.facility?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.facility == null) {
        success = await facilityProvider.createFacility(facility);
      } else {
        success = await facilityProvider.updateFacility(facility);
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.facility == null 
                ? 'Facility created successfully!' 
                : 'Facility updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(facilityProvider.error ?? 'Failed to save facility'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.facility == null ? 'Create Facility' : 'Edit Facility',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A5C2A),
        elevation: 0,
        actions: [
          if (_isPickingImages)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(),
                  const SizedBox(height: 24),
                  
                  _buildTextField(
                    controller: _nameController,
                    label: 'Facility Name',
                    icon: Icons.business,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    icon: Icons.description,
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _capacityController,
                          label: 'Capacity',
                          icon: Icons.people,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Required';
                            if (int.tryParse(v!) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Price/Hour (₹)',
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Required';
                            if (double.tryParse(v!) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _hoursController,
                    label: 'Operating Hours',
                    icon: Icons.access_time,
                    hint: 'e.g., 6:00 AM - 10:00 PM',
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Features', Icons.star),
                  const SizedBox(height: 12),
                  _buildDynamicList(
                    items: _features,
                    controller: _featureController,
                    onAdd: _addFeature,
                    onRemove: _removeFeature,
                    hint: 'Add a feature (e.g., Air Conditioning)',
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Rules', Icons.gavel),
                  const SizedBox(height: 12),
                  _buildDynamicList(
                    items: _rules,
                    controller: _ruleController,
                    onAdd: _addRule,
                    onRemove: _removeRule,
                    hint: 'Add a rule (e.g., No outside food)',
                  ),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveFacility,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A5C2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.facility == null ? 'Create Facility' : 'Update Facility',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A5C2A)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: const Text(
                'Facility Images',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${_imagesBase64.length} image(s)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imagesBase64.length + 1,
            itemBuilder: (context, index) {
              if (index == _imagesBase64.length) {
                return GestureDetector(
                  onTap: _isPickingImages ? null : _pickImages,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _isPickingImages
                        ? const Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Add Images', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                  ),
                );
              }
              return Stack(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(_imagesBase64[index])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A5C2A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A5C2A), width: 2),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A5C2A), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDynamicList({
    required List<String> items,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required String hint,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle, color: Color(0xFF1A5C2A), size: 32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.asMap().entries.map((entry) {
              int idx = entry.key;
              String item = entry.value;
              return Chip(
                label: Text(item),
                onDeleted: () => onRemove(idx),
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: Colors.grey[100],
              );
            }).toList(),
          ),
      ],
    );
  }
}