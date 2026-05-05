import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);

    return Scaffold(
      appBar: AppBar(
        title: Text('Help Center', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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
                  Text('Quick Start', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('- Create or update your resident profile via the Profile screen.', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                  Text('- Book amenities from the Bookings section.', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                  Text('- Report issues from the Report/Support screen. Attach photos when possible.', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                  const SizedBox(height: 12),
                  Text('Contact', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Admin / General Support: orelax.admin@gmail.com', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                  Text('Security (urgent incidents): kld060273@gmail.com', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                  const SizedBox(height: 12),
                  Text('Support Guidelines', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('- For non-urgent maintenance, include photos and your apartment number.', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                  Text('- For urgent safety incidents, call on-site security first then email the Security Team.', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                  const SizedBox(height: 12),
                  Text('Response times', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Standard requests: 24–48 business hours. Security incidents are prioritized.', style: GoogleFonts.poppins(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
