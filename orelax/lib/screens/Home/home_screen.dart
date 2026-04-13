import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/facility_provider.dart';
import '../../models/facility_model.dart';
import '../facilities_manager/create_edit_facility_screen.dart';
import '../facilities_manager/facility_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _role = 'resident';
  bool _roleResolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRole());
  }

  Future<void> _loadRole() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await auth.getUserData();
    if (!mounted) return;
    
    // Debug: Print user data to console
    print('=== USER DATA FROM FIREBASE ===');
    print('Full user data: $data');
    print('Role field: ${data?['role']}');
    print('================================');
    
    // Get role and normalize to lowercase
    final r = (data?['role'] as String?)?.trim().toLowerCase() ?? 'resident';
    
    setState(() {
      _role = r;
      _roleResolved = true;
    });
    
    print('Normalized role set to: $_role');
    
    // Load facilities if Facilities Manager
    if (_role == 'facility manager' || 
        _role == 'facilities manager' ||
        _role == 'facility_manager' ||
        _role == 'facilities_manager') {
      final facilityProvider = Provider.of<FacilityProvider>(context, listen: false);
      await facilityProvider.fetchFacilities();
    }
  }

  String get _tagline {
    switch (_role) {
      case 'security':
        return '★ Security · Access & monitoring';
      case 'maintenance':
        return '★ Maintenance · Work orders & repairs';
      case 'facility manager':
      case 'facilities manager':
      case 'facility_manager':
      case 'facilities_manager':
        return '★ Facilities Manager · Reservations & approvals';
      default:
        return '★ Secure Gated Community';
    }
  }

  String get _searchHint {
    switch (_role) {
      case 'security':
        return 'Search access, visitors, alerts...';
      case 'maintenance':
        return 'Search work orders, requests...';
      case 'facility manager':
      case 'facilities manager':
      case 'facility_manager':
      case 'facilities_manager':
        return 'Search facilities, registrations, payments...';
      default:
        return 'Search services, events...';
    }
  }

  bool get _usesNotificationsTab {
    return _role == 'security' ||
        _role == 'maintenance' ||
        _role == 'facility manager' ||
        _role == 'facilities manager' ||
        _role == 'facility_manager' ||
        _role == 'facilities_manager';
  }

  bool _isFacilitiesManager() {
    return _role == 'facility manager' || 
        _role == 'facilities manager' ||
        _role == 'facility_manager' ||
        _role == 'facilities_manager';
  }

  void _navigateToPage(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        // For facilities managers, navigate to booking history
        if (_role == 'facility manager' || 
            _role == 'facilities manager' ||
            _role == 'facility_manager' ||
            _role == 'facilities_manager') {
          Navigator.pushNamed(context, '/booking-history');
        } else {
          Navigator.pushNamed(context, '/chat');
        }
        break;
      case 2:
        Navigator.pushNamed(
          context,
          _usesNotificationsTab ? '/notifications' : '/report',
        );
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5C2A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.shield, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: const Text(
                              'ORELAX',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                color: Color(0xFF1A5C2A),
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        },
                      ),
                      Text(
                        _tagline,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Tooltip(
                    message: 'Notifications',
                    child: SvgPicture.asset(
                      'assets/icon/bell.svg',
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(
                        Colors.black87,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: 'Profile',
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFE0E0E0),
                        child: Icon(Icons.person, color: Colors.grey, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _searchHint,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Scrollable Content ──
            Expanded(
              child: !_roleResolved
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A5C2A),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildHomeScrollContent(),
                    ),
            ),
          ],
        ),
      ),

      // ── Floating Bottom Navigation ──
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C2A),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: 'assets/icon/house.svg',
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => _navigateToPage(0),
              ),
              // Booking History for Facilities Managers, Chat for others
              _isFacilitiesManager()
                  ? _NavItem(
                      icon: 'assets/icon/calendar.svg',
                      label: 'Bookings',
                      isActive: _currentIndex == 1,
                      onTap: () => _navigateToPage(1),
                    )
                  : _ChatNavItem(
                      isActive: _currentIndex == 1,
                      onTap: () => _navigateToPage(1),
                      showNotificationBadge: _usesNotificationsTab,
                    ),
              _NavItem(
                icon: _usesNotificationsTab
                    ? 'assets/icon/bell.svg'
                    : 'assets/icon/triangle-alert.svg',
                label: _usesNotificationsTab ? 'Notifications' : 'Report',
                isActive: _currentIndex == 2,
                onTap: () => _navigateToPage(2),
              ),
              _NavItem(
                icon: 'assets/icon/user-round.svg',
                label: 'Profile',
                isActive: _currentIndex == 3,
                onTap: () => _navigateToPage(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One scroll area per role — CORRECTED VERSION
  Widget _buildHomeScrollContent() {
    final normalizedRole = _role.toLowerCase().trim();
    
    print('=== ROUTING: User role is "$normalizedRole" ===');
    
    // Security Role
    if (normalizedRole == 'security') {
      print('Routing to Security Dashboard');
      return _buildSecurityHomeContent();
    }
    
    // Maintenance Role
    if (normalizedRole == 'maintenance') {
      print('Routing to Maintenance Dashboard');
      return _buildMaintenanceHomeContent();
    }
    
    // Facilities Manager Role
    if (normalizedRole == 'facility manager' || 
        normalizedRole == 'facilities manager' ||
        normalizedRole == 'facility_manager' ||
        normalizedRole == 'facilities_manager') {
      print('Routing to Facilities Manager Dashboard');
      return _buildFacilitiesManagerHomeContent();
    }
    
    // Default to Resident (also handles 'admin', 'resident', etc.)
    print('Routing to Resident Dashboard');
    return _buildResidentHomeContent();
  }

  /// Security Dashboard
  Widget _buildSecurityHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C2A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C518),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ANNOUNCEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Security desk briefing',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitor access, visitors, and alerts from the cards below — same bottom menu as everyone.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/alerts'),
                    child: const Row(
                      children: [
                        Text(
                          'View alerts ',
                          style: TextStyle(
                            color: Color(0xFFF5C518),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Icon(Icons.arrow_forward,
                            color: Color(0xFFF5C518), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'OUR SERVICES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/access-control'),
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF1A5C2A), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.4,
          children: [
            _ServiceCard(
              icon: Icons.qr_code_scanner,
              iconColor: const Color(0xFF5B8DEF),
              title: 'Access',
              subtitle: 'Grant & QR control',
              onTap: () => Navigator.pushNamed(context, '/access-control'),
            ),
            _ServiceCard(
              icon: Icons.people_outline,
              iconColor: const Color(0xFFE07B3F),
              title: 'Visitors',
              subtitle: 'Guest management',
              onTap: () => Navigator.pushNamed(context, '/visitors'),
            ),
            _ServiceCard(
              icon: Icons.warning_amber_outlined,
              iconColor: const Color(0xFFE05C8A),
              title: 'Alerts',
              subtitle: 'Incidents & notices',
              onTap: () => Navigator.pushNamed(context, '/alerts'),
            ),
            _ServiceCard(
              icon: Icons.history,
              iconColor: const Color(0xFF9B59B6),
              title: 'Access logs',
              subtitle: 'Recent activity',
              onTap: () => Navigator.pushNamed(context, '/access-logs'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF1A5C2A),
                    child: Icon(Icons.security, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shift note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Today • Security',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/access-logs'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A5C2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LOGS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward,
                              color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Text(
                  'Check visitor queue and gate cameras during peak hours. Use Access for new entries.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  /// Maintenance Dashboard
  Widget _buildMaintenanceHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C2A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C518),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ANNOUNCEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Maintenance queue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Open work orders and pending requests below — Home · Chat · Report · Profile stay the same.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/work-orders'),
                    child: const Row(
                      children: [
                        Text(
                          'Open work orders ',
                          style: TextStyle(
                            color: Color(0xFFF5C518),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Icon(Icons.arrow_forward,
                            color: Color(0xFFF5C518), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'OUR SERVICES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/schedule'),
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF1A5C2A), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.4,
          children: [
            _ServiceCard(
              icon: Icons.build_circle_outlined,
              iconColor: const Color(0xFF5B8DEF),
              title: 'Work orders',
              subtitle: 'Active jobs',
              onTap: () => Navigator.pushNamed(context, '/work-orders'),
            ),
            _ServiceCard(
              icon: Icons.pending_actions_outlined,
              iconColor: const Color(0xFFE07B3F),
              title: 'Pending',
              subtitle: 'Awaiting action',
              onTap: () => Navigator.pushNamed(context, '/pending-requests'),
            ),
            _ServiceCard(
              icon: Icons.calendar_today_outlined,
              iconColor: const Color(0xFFE05C8A),
              title: 'Schedule',
              subtitle: 'Your calendar',
              onTap: () => Navigator.pushNamed(context, '/schedule'),
            ),
            _ServiceCard(
              icon: Icons.report_problem_outlined,
              iconColor: const Color(0xFF9B59B6),
              title: 'Report',
              subtitle: 'Submit an issue',
              onTap: () => Navigator.pushNamed(context, '/report'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF1A5C2A),
                    child: Icon(Icons.build, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Today • Maintenance',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/pending-requests'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A5C2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PENDING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward,
                              color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Text(
                  'Prioritize common-area repairs before unit callbacks. Use Report in the bottom bar for new tickets.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  /// Facilities Manager Dashboard
  Widget _buildFacilitiesManagerHomeContent() {
    final facilityProvider = Provider.of<FacilityProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Card with Add Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C2A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Facilities Manager',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.pushNamed(context, '/create-facility');
                      if (result == true) {
                        facilityProvider.fetchFacilities();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C518),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 18, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'Add Facility',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage community facilities, view bookings, and update facility information.',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Facilities List Title
        const Text(
          'MANAGE FACILITIES',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 16),
        
        // Facilities Grid or List
        if (facilityProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF1A5C2A)),
            ),
          )
        else if (facilityProvider.facilities.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.business, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No facilities yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the + Add Facility button to create your first facility',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: facilityProvider.facilities.length,
            itemBuilder: (context, index) {
              final facility = facilityProvider.facilities[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/facility-detail', 
                    arguments: facility.id
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: facility.imagesBase64.isNotEmpty
                            ? Image.memory(
                                base64Decode(facility.imagesBase64.first),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  );
                                },
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facility.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.people, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Capacity: ${facility.capacity}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    facility.hours,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FREE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        
        const SizedBox(height: 100),
      ],
    );
  }

  /// Resident Dashboard
  Widget _buildResidentHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Announcement Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C2A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C518),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ANNOUNCEMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Weekend Festival',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join us this Saturday for the\ncommunity BBQ and music night.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/events');
                    },
                    child: const Row(
                      children: [
                        Text(
                          'Learn More ',
                          style: TextStyle(
                            color: Color(0xFFF5C518),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Icon(Icons.arrow_forward,
                            color: Color(0xFFF5C518), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Resident shortcuts
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RESIDENT SERVICES',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/helping-staff');
              },
              child: const Text(
                'View All',
                style: TextStyle(
                    color: Color(0xFF1A5C2A), fontSize: 13),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Resident Shortcut Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.4,
          children: [
            _ServiceCard(
              icon: Icons.support_agent,
              iconColor: const Color(0xFF5B8DEF),
              title: 'Helping Staff',
              subtitle: 'Request cleaning, repair, or service',
              onTap: () => Navigator.pushNamed(context, '/helping-staff'),
            ),
            _ServiceCard(
  icon: Icons.event,
  iconColor: const Color(0xFFE07B3F),
  title: 'Events',
  subtitle: 'Community gatherings & workshops',
  onTap: () => Navigator.pushNamed(context, '/events'),  // This should go to events screen
),
            _ServiceCard(
              icon: Icons.qr_code_2_rounded,
              iconColor: const Color(0xFF1A5C2A),
              title: 'QR code',
              subtitle: 'Generate Qr code for guests',
              onTap: () => Navigator.pushNamed(context, '/guest_qr'),
            ),
            _ServiceCard(
              icon: Icons.place,
              iconColor: const Color(0xFF9B59B6),
              title: 'Facilities',
              subtitle: 'Check available spaces & hours',
              onTap: () => Navigator.pushNamed(context, '/facilities'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Community Post
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF1A5C2A),
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Post',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '2 hours ago • General',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/feed');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A5C2A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'GO TO FEED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward,
                              color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Text(
                  '"Does anyone know a good local tutor for mathematics? My daughter needs some help with her finals..."',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }
}

// ── Chat Nav Item with Notification Badge ──
class _ChatNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final bool showNotificationBadge;

  const _ChatNavItem({
    required this.isActive,
    required this.onTap,
    required this.showNotificationBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Chat',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icon/message-circle.svg',
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      isActive ? Colors.white : Colors.white60,
                      BlendMode.srcIn,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    const Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (showNotificationBadge)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav Item ──
class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                icon,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  isActive ? Colors.white : Colors.white60,
                  BlendMode.srcIn,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Service Card ──
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if (subtitle.isNotEmpty)
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}