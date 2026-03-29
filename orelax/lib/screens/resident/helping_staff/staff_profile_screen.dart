import 'package:flutter/material.dart';
import 'staff_member.dart';

class StaffProfileScreen extends StatelessWidget {
  final StaffMember staff;

  const StaffProfileScreen({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A5C2A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          staff.name,
          style: const TextStyle(color: Color(0xFF1A5C2A)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getProfessionIcon(staff.profession),
                      color: const Color(0xFF1A5C2A).withOpacity(0.6),
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.name,
                          style: const TextStyle(
                            color: Color(0xFF1A2A1A),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          staff.profession,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFFB74D),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              staff.rating.toString(),
                              style: const TextStyle(
                                color: Color(0xFF1A2A1A),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${staff.yearsOfExperience} years exp.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              color: Color(0xFFE0E0E0),
              thickness: 1,
              indent: 24,
              endIndent: 24,
            ),

            // About section
            Container(
              margin: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      color: Color(0xFF1A2A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getAboutText(staff),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Price section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      color: Color(0xFF1A2A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${staff.hourlyRate}/hour',
                    style: const TextStyle(
                      color: Color(0xFF1A5C2A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hire button
            Container(
              margin: const EdgeInsets.all(24),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showHireDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5C2A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Hire',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAboutText(StaffMember staff) {
    switch (staff.profession.toLowerCase()) {
      case 'cleaning':
        return '${staff.name} is a professional cleaner with ${staff.yearsOfExperience} years of experience. Specializes in residential and commercial cleaning services. Known for attention to detail, reliability, and using eco-friendly products.';
      case 'plumber':
        return '${staff.name} is a licensed plumber with ${staff.yearsOfExperience} years of experience. Expert in pipe repairs, installations, leak detection, and emergency plumbing services. Committed to quality work and customer satisfaction.';
      case 'electrician':
        return '${staff.name} is a certified electrician with ${staff.yearsOfExperience} years of experience. Specializes in wiring, installations, repairs, and electrical safety inspections. Dedicated to providing safe and reliable electrical services.';
      default:
        return '${staff.name} is a professional service provider with ${staff.yearsOfExperience} years of experience in ${staff.profession}. Committed to delivering high-quality service with professionalism and expertise.';
    }
  }

  void _showHireDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Request Sent!',
          style: TextStyle(color: Color(0xFF1A5C2A)),
        ),
        content: Text(
          'Your hiring request has been sent to ${staff.name}. They will contact you shortly.',
          style: const TextStyle(color: Color(0xFF1A2A1A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF1A5C2A)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProfessionIcon(String profession) {
    switch (profession.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'plumber':
        return Icons.plumbing;
      case 'electrician':
        return Icons.electrical_services;
      default:
        return Icons.work;
    }
  }
}
