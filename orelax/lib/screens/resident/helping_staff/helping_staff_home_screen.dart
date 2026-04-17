import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orelax/services/employee_api_service.dart';
import 'package:orelax/models/employee_model.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import 'helping_staff_list_screen.dart';

class HelpingStaffScreen extends StatefulWidget {
  const HelpingStaffScreen({super.key});

  @override
  State<HelpingStaffScreen> createState() => _HelpingStaffScreenState();
}

class _HelpingStaffScreenState extends State<HelpingStaffScreen> {
  late Future<List<Employee>> _topRatedFuture;

  @override
  void initState() {
    super.initState();
    _topRatedFuture = _loadTopRated();
  }

  Future<List<Employee>> _loadTopRated() async {
    try {
      final allEmployees = await EmployeeApiService.getAllEmployees();
      // For now, let's just take the first 2 as "Top Rated"
      return allEmployees.take(2).toList();
    } catch (e) {
      debugPrint('Error loading top rated: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shared dark green color for consistency
    const Color darkGreen = Color(0xFF1A5C2A);

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
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              // Promo Banner
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child!,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        darkGreen, // Use darkGreen as in the announcement bar image
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Floating Circles
                        Positioned(
                          right: -20,
                          top: -20,
                          child: _FloatingCircle(
                            size: 150,
                            color: Colors.white.withOpacity(0.08),
                            duration: const Duration(seconds: 4),
                          ),
                        ),
                        Positioned(
                          right: 40,
                          bottom: -30,
                          child: _FloatingCircle(
                            size: 100,
                            color: Colors.white.withOpacity(0.08),
                            duration: const Duration(seconds: 6),
                          ),
                        ),

                        // Foreground content (Text and Announcement badge)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCC33),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "OFFER",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Get 25% Offer",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "On your first cleaning service.\nBook now and save big!",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    "Book Your Staff",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: const Color(0xFFFFCC33),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Color(0xFFFFCC33),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Categories
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: child!,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.cleaning_services,
                                size: 48,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
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

              FutureBuilder<List<Employee>>(
                future: _topRatedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: darkGreen));
                  }

                  final topRated = snapshot.data ?? [];

                  if (topRated.isEmpty) {
                    return Center(
                      child: Text(
                        "No employees found",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topRated.length,
                    itemBuilder: (context, index) {
                      final emp = topRated[index];
                      final name = emp.fullName;
                      final category = emp.workCategory;
                      final photo = EmployeeApiService.getImageUrl(emp.photo);

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + (index * 150)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: _TopRatedHoverItem(
                          name: name,
                          role: category,
                          price: "Experience: ${emp.experience} yrs",
                          ratingText: "New",
                          imageUrl: photo,
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        HelpingStaffListScreen(
                                  categoryName: category,
                                  imageUrl: photo,
                                ),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOutQuart;
                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child);
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
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
              bgImage =
                  'https://img.freepik.com/free-photo/young-cleaner-smiling-looking-camera_1187-5735.jpg';
              break;
            case 'repairing':
              bgImage =
                  'https://img.freepik.com/free-photo/working-with-screwdriver-male-mechanic-in-uniform-is-in-workplace_146671-15891.jpg';
              break;
            case 'plumbing':
              bgImage =
                  'https://img.freepik.com/free-photo/plumber-pointing-up_1368-71328.jpg';
              break;
            case 'electrical':
            default:
              bgImage =
                  'https://img.freepik.com/free-photo/electrician-builder-working-with-wires_1303-31780.jpg';
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
                  color: _isHovered
                      ? darkGreen.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _isHovered ? 15 : 10,
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

class _FloatingCircle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _FloatingCircle({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<_FloatingCircle> createState() => _FloatingCircleState();
}

class _FloatingCircleState extends State<_FloatingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: const Offset(-0.1, -0.1),
      end: const Offset(0.2, 0.2),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TopRatedHoverItem extends StatefulWidget {
  final String name;
  final String role;
  final String price;
  final String ratingText;
  final String imageUrl;
  final VoidCallback onTap;

  const _TopRatedHoverItem({
    required this.name,
    required this.role,
    required this.price,
    required this.ratingText,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  State<_TopRatedHoverItem> createState() => _TopRatedHoverItemState();
}

class _TopRatedHoverItemState extends State<_TopRatedHoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);
    const Color highlightGreen = Color(0xFF2E7D32);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isHovered ? highlightGreen : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered ? Colors.transparent : Colors.grey.shade200,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: highlightGreen.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    // Worker Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.imageUrl,
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
                            widget.name,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _isHovered ? Colors.white : darkGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.role,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _isHovered
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.price,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isHovered ? Colors.white : darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right Arrow Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isHovered ? Colors.white : darkGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: _isHovered ? darkGreen : Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                // Rating Badge (Top Right)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? Colors.white.withOpacity(0.2)
                          : darkGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.ratingText,
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
        ),
      ),
    );
  }
}
