import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  List<Map<String, dynamic>> _testimonials = [];

  static const String _prefsKey = 'orelax_testimonials';

  @override
  void initState() {
    super.initState();
    _loadTestimonials();
  }

  Future<void> _loadTestimonials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      final List decoded = jsonDecode(raw);
      setState(() {
        _testimonials = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _saveTestimonials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_testimonials));
  }

  void _addTestimonial() {
    final name = _nameController.text.trim();
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a comment', style: GoogleFonts.poppins(color: Colors.white))),
      );
      return;
    }

    final entry = {
      'name': name.isEmpty ? 'Anonymous' : name,
      'comment': comment,
      'rating': _rating,
      'date': DateTime.now().toIso8601String(),
    };

    setState(() {
      _testimonials.insert(0, entry);
    });
    _saveTestimonials();

    _nameController.clear();
    _commentController.clear();
    setState(() => _rating = 5);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thank you for your feedback', style: GoogleFonts.poppins(color: Colors.white))),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);

    return Scaffold(
      appBar: AppBar(
        title: Text('About ORELAX', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkGreen),
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What is ORELAX', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'ORELAX is a resident-centered community management platform designed to simplify daily life in apartment complexes and residential buildings. We provide secure tools for residents, property managers, and security teams to communicate, book facilities, report issues, and manage visitors.',
                    style: GoogleFonts.poppins(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  Text('Our mission', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'To make residential living safer, more convenient, and more connected by delivering an easy, secure, and reliable digital experience for residents and staff.',
                    style: GoogleFonts.poppins(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  Text('Key features', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _featureRow('Facility & amenity bookings'),
                  _featureRow('Event announcements & community news'),
                  _featureRow('Incident reporting & secure communications'),
                  _featureRow('Visitor QR passes & guest management'),
                  _featureRow('Real-time notifications and alerts'),
                  const SizedBox(height: 16),
                  Text('© 2024 ORELAX. All rights reserved.', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Testimonials form
            Text('Share your feedback', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Your name (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Your comment', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Rate the app', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      ...List.generate(5, (i) {
                        final idx = i + 1;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            idx <= _rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFF1A5C2A),
                          ),
                          onPressed: () => setState(() => _rating = idx),
                        );
                      }),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _addTestimonial,
                        style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
                        child: Text('Submit', style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Testimonials list
            Text('Resident testimonials', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_testimonials.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Text('No testimonials yet — be the first to leave feedback!', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
              )
            else
              Column(
                children: _testimonials.map((t) {
                  final date = DateTime.tryParse(t['date'] ?? '')?.toLocal();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(t['name'] ?? 'Anonymous', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Row(children: List.generate((t['rating'] ?? 0) as int, (_) => const Icon(Icons.star, size: 16, color: Color(0xFF1A5C2A)))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(t['comment'] ?? '', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Text(date != null ? '${date.day}/${date.month}/${date.year}' : '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF1A5C2A)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.grey.shade700))),
        ],
      ),
    );
  }
}
