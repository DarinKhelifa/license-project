import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/employee_provider.dart';
import '../../../models/employee_model.dart';

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
  @override
  void initState() {
    super.initState();
    // Fetch employees when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
    });
  }

  List<Employee> get filteredEmployees {
    final employeeProvider = context.watch<EmployeeProvider>();
    return employeeProvider.employees.where((employee) => 
      employee.workCategory.toLowerCase() == widget.categoryName.toLowerCase()
    ).toList();
  }

  Widget _buildStaffItem({
    required Employee employee,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            children: [
              // Avatar
              ClipOval(
                child: employee.photo.isNotEmpty
                  ? Image.network(
                      employee.photo,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
              ),
              const SizedBox(width: 16),
              // Name and Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${employee.firstName} ${employee.lastName}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.experience,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Phone Icon
              const Icon(Icons.phone, color: Colors.grey, size: 24),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200, indent: 20, endIndent: 20),
      ],
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
                Image.network(
                  widget.imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 250,
                    color: darkGreen,
                    child: const Icon(Icons.image, color: Colors.white54, size: 50),
                  ),
                ),
                // Dark Overlay
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.7),
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
                // Category Name
                Positioned(
                  bottom: 24,
                  left: 20,
                  child: Text(
                    widget.categoryName,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
              // If list is empty, show empty state
              child: filteredEmployees.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 80.0),
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
                            "No staff available yet",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  // Otherwise, render list items dynamically
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        return _buildStaffItem(
                          employee: filteredEmployees[index],
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

class _AnimatedCircleBackButton extends StatefulWidget {
  const _AnimatedCircleBackButton();

  @override
  State<_AnimatedCircleBackButton> createState() => _AnimatedCircleBackButtonState();
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
