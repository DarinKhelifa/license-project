import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/event_model.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/auth_provider.dart';
import 'dart:convert';

class EditEventScreen extends StatefulWidget {
  final Event event;
  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedCategory = 'social';
  String? _imageBase64;
  bool _isLoading = false;
  bool _isPickingImage = false;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'social', 'label': 'Social', 'icon': '🎉'},
    {'value': 'sports', 'label': 'Sports', 'icon': '⚽'},
    {'value': 'educational', 'label': 'Educational', 'icon': '📚'},
    {'value': 'workshop', 'label': 'Workshop', 'icon': '🔧'},
    {'value': 'festival', 'label': 'Festival', 'icon': '🎪'},
    {'value': 'other', 'label': 'Other', 'icon': '📅'},
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e.title);
    _descriptionController = TextEditingController(text: e.description);
    _locationController = TextEditingController(text: e.location);
    _capacityController = TextEditingController(text: e.capacity > 0 ? e.capacity.toString() : '');
    _selectedDate = e.date;
    _selectedTime = TimeOfDay(hour: int.parse(e.time.split(':')[0]), minute: int.parse(e.time.split(':')[1].split(' ').first));
    _selectedCategory = e.category;
    _imageBase64 = e.imageBase64;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => _imageBase64 = base64Encode(bytes));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image selected')));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.user;

    final updated = Event(
      id: widget.event.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      time: _selectedTime.format(context),
      location: _locationController.text.trim(),
      category: _selectedCategory,
      imageBase64: _imageBase64,
      capacity: int.tryParse(_capacityController.text.trim()) ?? 0,
      currentRegistrations: widget.event.currentRegistrations,
      status: widget.event.status,
      createdBy: widget.event.createdBy,
      createdByName: widget.event.createdByName,
      createdAt: widget.event.createdAt,
      isActive: widget.event.isActive,
      approvedBy: widget.event.approvedBy,
      approvedAt: widget.event.approvedAt,
    );

    final provider = Provider.of<EventProvider>(context, listen: false);
    final success = await provider.updateEvent(updated);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event updated')));
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to update event')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: (_imageBase64 != null && _imageBase64!.trim().isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(base64Decode(_imageBase64!), fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Add/Change Event Image', style: TextStyle(color: Colors.grey.shade600)),
                          ]),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)), validator: (v) => v?.isEmpty ?? true ? 'Title required' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)), validator: (v) => v?.isEmpty ?? true ? 'Description required' : null),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: GestureDetector(onTap: _selectDate, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.calendar_today, color: Color(0xFF034808)), const SizedBox(width: 8), Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}')] )))),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(onTap: _selectTime, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.access_time, color: Color(0xFF034808)), const SizedBox(width: 8), Text(_selectedTime.format(context))])))),
                ]),
                const SizedBox(height: 12),
                TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)), validator: (v) => v?.isEmpty ?? true ? 'Location required' : null),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map<DropdownMenuItem<String>>((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['value'] as String,
                      child: Row(children: [Text(cat['icon'] as String), const SizedBox(width: 8), Text(cat['label'] as String)]),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _capacityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.people))),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _submitUpdate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF034808)), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Event'))),
              ]),
            ),
          ),
          if (_isPickingImage) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: Color(0xFF034808)))),
        ],
      ),
    );
  }
}
