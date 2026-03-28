import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'helping_staff_list_screen.dart';

class HelpingStaffScreen extends StatelessWidget {
  const HelpingStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Shared dark green color for consistency
    const Color darkGreen = Color(0xFF1A5C2A);
    const Color lightGreen = Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkGreen),
        centerTitle: true,
        title: Text(
          "Our Staff",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkGreen,
          ),
        ),
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.arrow_back, color: darkGreen, size: 20),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 8, bottom: 8),
            child: Container(
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: darkGreen),
              ),
              child: const Icon(Icons.notifications_none_outlined, color: darkGreen, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              // Promo Banner
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Woman Image taking right side
                      Positioned(
                        right: -10,
                        top: 0,
                        bottom: 0,
                        child: Image.asset(
                          'assets/images/Cleaning_women.png',
                          fit: BoxFit.fitHeight,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(
                            width: 140,
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                      ),
                      // Foreground text
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Get 25% OFF on\nHome Cleaning",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Lorem ipsum dolor sit amg\namet consectetur.",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                "View",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Categories
              Text(
                "Categories",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _CategoryCard(
                      title: "Cleaning",
                      iconWidget: Image.asset(
                        'assets/images/cleaning.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.cleaning_services,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _CategoryCard(
                      title: "Repairing",
                      iconWidget: Image.asset(
                        'assets/images/plimbierstaff.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.cleaning_services,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _CategoryCard(
                      title: "Plumbing",
                      iconWidget: Image.asset(
                        'assets/images/cleaning.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.cleaning_services,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _CategoryCard(
                      title: "Electrical",
                      iconWidget: Image.asset(
                        'assets/images/electricien.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.cleaning_services,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Top Rated
              Text(
                "Top Rated",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                itemBuilder: (context, index) {
                  final bool isFirst = index == 0;
                  return _buildTopRatedItem(
                    name: isFirst ? "Devon Lane" : "Robert Fox",
                    role: isFirst ? "Plumber" : "Painter",
                    price: isFirst ? "\$20/Hour" : "\$15/Hour",
                    ratingText: isFirst ? "4.2" : "3.9",
                    imageUrl: isFirst 
                        ? 'https://img.freepik.com/free-photo/portrait-white-man-isolated_53876-40306.jpg'
                        : 'https://img.freepik.com/free-photo/painter-man-isolated-white-background_1368-29364.jpg',
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRatedItem({
    required String name,
    required String role,
    required String price,
    required String ratingText,
    required String imageUrl,
  }) {
    const Color darkGreen = Color(0xFF1A5C2A);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Worker Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        price,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Arrow Button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ),
              ],
            ),
            // Rating Badge (Top Right)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ratingText,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.star, color: Colors.amber, size: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final Widget iconWidget;

  const _CategoryCard({
    required this.title,
    required this.iconWidget,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: () {
          String bgImage = '';
          switch (widget.title.toLowerCase()) {
            case 'cleaning':
              bgImage = 'https://img.freepik.com/free-photo/young-cleaner-smiling-looking-camera_1187-5735.jpg';
              break;
            case 'repairing':
              bgImage = 'https://img.freepik.com/free-photo/working-with-screwdriver-male-mechanic-in-uniform-is-in-workplace_146671-15891.jpg';
              break;
            case 'plumbing':
              bgImage = 'https://img.freepik.com/free-photo/plumber-pointing-up_1368-71328.jpg';
              break;
            case 'electrical':
            default:
              bgImage = 'https://img.freepik.com/free-photo/electrician-builder-working-with-wires_1303-31780.jpg';
              break;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HelpingStaffListScreen(
                categoryName: widget.title,
                imageUrl: bgImage,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 115,
            height: 140,
            decoration: BoxDecoration(
              color: _isHovered ? darkGreen : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: _isHovered ? Colors.transparent : Colors.grey.shade200,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: widget.iconWidget,
                ),
                const SizedBox(height: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isHovered ? Colors.white : darkGreen,
                  ),
                  child: Text(widget.title),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
