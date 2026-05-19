import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orelax/models/employee_model.dart';
// import 'package:orelax/screens/resident/helping_staff/staff_profile_screen.dart';
import 'package:orelax/services/employee_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpingStaffListScreen extends StatefulWidget {
  final String categoryName;
  final String imageUrl;

  const HelpingStaffListScreen({
    super.key,
    required this.categoryName,
    required this.imageUrl,
  });

  @override
  State<HelpingStaffListScreen> createState() => _HelpingStaffListScreenState();
}

class _HelpingStaffListScreenState extends State<HelpingStaffListScreen> {
  late Future<List<Employee>> _staffFuture;
  List<Employee>? _allStaff;
  List<Employee>? _filteredStaff;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  String _canonicalCategory(String value) {
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'cleaning':
        return 'cleaning';
      case 'repairing':
      case 'repair':
        return 'repair';
      case 'plumbing':
      case 'plumber':
        return 'plumber';
      case 'electrical':
      case 'electrician':
        return 'electrician';
      case 'all':
      case 'all staff':
      case 'staff':
        return '';
      default:
        return normalized;
    }
  }

  @override
  void initState() {
    super.initState();
    _staffFuture = _loadStaff();
  }

  Future<List<Employee>> _loadStaff() async {
    try {
      final allEmployees = await EmployeeApiService.getAllEmployees();
      // Debug print to see what we're getting
      debugPrint('Loaded ${allEmployees.length} employees total');

      // Filter by category
      final targetCategory = _canonicalCategory(widget.categoryName);
      final filtered = allEmployees.where((emp) {
        if (targetCategory.isEmpty) return true;
        final category = _canonicalCategory(emp.workCategory);
        return category == targetCategory;
      }).toList();

      debugPrint(
          'Filtered to ${filtered.length} employees for ${widget.categoryName}');

      setState(() {
        _allStaff = filtered;
        _filteredStaff = filtered;
      });
      return filtered;
    } catch (e) {
      debugPrint('Error loading staff: $e');
      rethrow;
    }
  }

  void _filterStaff(String query) {
    if (_allStaff == null) return;
    setState(() {
      if (query.isEmpty) {
        _filteredStaff = _allStaff;
      } else {
        _filteredStaff = _allStaff!.where((staff) {
          final name = staff.fullName.toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildStaffItem({
    required String name,
    required String rating,
    required String avatarUrl,
    required String phone,
    required VoidCallback onTap,
  }) {
    return _StaffItemWithHover(
      name: name,
      rating: rating,
      avatarUrl: avatarUrl,
      phone: phone,
      onTap: onTap,
    );
  }

  Widget _buildHeaderImage(
      String category, String networkUrl, Color fallbackColor) {
    String assetPath = '';
    switch (category.toLowerCase()) {
      case 'cleaning':
        assetPath = 'assets/images/cleaning_staff.png';
        break;
      case 'plumbing':
        assetPath = 'assets/images/plombier.png';
        break;
      case 'electrical':
        assetPath = 'assets/images/electrician_staff.png';
        break;
      case 'repairing':
        assetPath = 'assets/images/repairing.png';
        break;
    }

    if (assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        width: double.infinity,
        height: 250, // Increased height
        fit: BoxFit.cover, // Changed to cover to fill the container
        errorBuilder: (context, error, stackTrace) =>
            _buildNetworkOrFallback(networkUrl, fallbackColor),
      );
    }
    return _buildNetworkOrFallback(networkUrl, fallbackColor);
  }

  Widget _buildNetworkOrFallback(String url, Color fallback) {
    return Image.network(
      url,
      width: double.infinity,
      height: 250, // Increased height
      fit: BoxFit.cover, // Changed to cover
      errorBuilder: (context, error, stackTrace) => Container(
        width: double.infinity,
        height: 250,
        color: fallback,
        child: const Icon(Icons.image, color: Colors.white54, size: 50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Image with Back Button
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Background Image
                _buildHeaderImage(
                    widget.categoryName, widget.imageUrl, darkGreen),

                Container(
                  width: double.infinity,
                  height: 250, // Match header height
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),

                // Back Button (Animated)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  child: const _AnimatedCircleBackButton(),
                ),

                // Search/Close Icon
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          _filterStaff('');
                        }
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                // Search Field or Category Name
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSearching
                        ? Container(
                            key: const ValueKey('searchField'),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: _filterStaff,
                              style: GoogleFonts.poppins(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Search in ${widget.categoryName}...',
                                hintStyle:
                                    GoogleFonts.poppins(color: Colors.grey),
                                border: InputBorder.none,
                                icon: const Icon(Icons.search,
                                    color: Colors.grey, size: 20),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            key: const ValueKey('categoryTitle'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.categoryName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Staff List Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: FutureBuilder<List<Employee>>(
                future: _staffFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(50.0),
                      child: Center(
                        child: CircularProgressIndicator(color: darkGreen),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          "Error loading staff. Please try again later.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  final displayList = _filteredStaff ?? [];

                  if (displayList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(80.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9), // Light green
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people_outline,
                              size: 64,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isSearching
                                ? "No results found"
                                : "No staff available yet",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final emp = displayList[index];
                      final String name = emp.fullName;
                      final String category = emp.workCategory;
                      final String avatarUrl =
                          EmployeeApiService.getImageUrl(emp.photo);

                      return _buildStaffItem(
                        name: name,
                        rating: "4.5/5",
                        avatarUrl: avatarUrl,
                        phone: emp.phone,
                        onTap: () {
                          // No navigation - staff items are not clickable
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffItemWithHover extends StatefulWidget {
  final String name;
  final String rating;
  final String avatarUrl;
  final String phone;
  final VoidCallback onTap;

  const _StaffItemWithHover({
    required this.name,
    required this.rating,
    required this.avatarUrl,
    required this.phone,
    required this.onTap,
  });

  @override
  State<_StaffItemWithHover> createState() => _StaffItemWithHoverState();
}

class _StaffItemWithHoverState extends State<_StaffItemWithHover> {
  bool _isPhoneHovered = false;

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);

    return InkWell(
      onTap: widget.onTap,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
            child: Row(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade100, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      widget.avatarUrl,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 55,
                        height: 55,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Name and Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            widget.rating,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Phone Icon with Circle and Hover
                MouseRegion(
                  onEnter: (_) => setState(() => _isPhoneHovered = true),
                  onExit: (_) => setState(() => _isPhoneHovered = false),
                  child: GestureDetector(
                    onTap: () async {
                      final Uri launchUri = Uri(
                        scheme: 'tel',
                        path: widget.phone,
                      );
                      if (await canLaunchUrl(launchUri)) {
                        await launchUrl(launchUri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not launch phone dialer')),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isPhoneHovered
                            ? darkGreen.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: _isPhoneHovered
                              ? darkGreen
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.phone,
                        color: _isPhoneHovered
                            ? darkGreen
                            : Colors.black.withOpacity(0.7),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 20,
              endIndent: 20),
        ],
      ),
    );
  }
}

class _AnimatedCircleBackButton extends StatefulWidget {
  const _AnimatedCircleBackButton();

  @override
  State<_AnimatedCircleBackButton> createState() =>
      _AnimatedCircleBackButtonState();
}

class _AnimatedCircleBackButtonState extends State<_AnimatedCircleBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: () => Navigator.pop(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? darkGreen : Colors.white,
            boxShadow: [
              if (!_isHovered)
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Icon(
            Icons.arrow_back,
            color: _isHovered ? Colors.white : Colors.black87,
            size: 22,
          ),
        ),
      ),
    );
  }
}
