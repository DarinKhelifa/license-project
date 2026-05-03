import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/facility_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/notification_provider.dart';
import '../Environment/temperature_screen.dart';
import '../../widgets/notification_bell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _role = 'resident';
  bool _roleResolved = false;
  String _userName = '';

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
    print('=== USER DATA ===');
    print('Full user data: $data');
    print('Role field: ${data?['role']}');
    print('================================');

    // Get role and normalize to lowercase
    final r = (data?['role'] as String?)?.trim().toLowerCase() ?? 'resident';

    setState(() {
      _role = r;
      _roleResolved = true;
      _userName = (data?['name'] as String?) ?? auth.userName ?? '';
    });

    print('Normalized role set to: $_role');

    // Load facilities if Facilities Manager
    if (_role == 'facility manager' ||
        _role == 'facilities manager' ||
        _role == 'facility_manager' ||
        _role == 'facilities_manager') {
      final facilityProvider =
          Provider.of<FacilityProvider>(context, listen: false);
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
    if (index == 4) {
      Navigator.pushNamed(context, '/portal');
      return;
    }
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
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Modern Top Header (replaces hero image) ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5C2A), Color(0xFF2A7D3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORELAX',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          _tagline,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/temperature'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/icon/thermometer-sun.svg',
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const NotificationBell(),
                        const SizedBox(width: 10),
                        _AnimatedProfileButton(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // ── Search bar under header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: _searchHint,
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (query) {},
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF8F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.tune, color: const Color(0xFF1A5C2A), size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Welcome message ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome Home, ${_userName.isNotEmpty ? _userName.split(' ').first : 'Guest'}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Scrollable Content ──
            Expanded(
              child: !_roleResolved
                  ? Center(
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 3.14 * 2,
                            child: const CircularProgressIndicator(
                              color: Color(0xFF1A5C2A),
                              strokeWidth: 3,
                            ),
                          );
                        },
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
      // ...existing code for bottomNavigationBar...
      bottomNavigationBar: _role.toLowerCase() != 'resident'
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                height: 75,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A5C2A),
                      Color(0xFF2A7D3A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A5C2A).withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: DockNavBar(
                  items: [
                    _DockNavBarItem(
                      icon: 'assets/icon/house.svg',
                      label: 'Home',
                      isActive: _currentIndex == 0,
                      onTap: () => _navigateToPage(0),
                    ),
                    _isFacilitiesManager()
                        ? _DockNavBarItem(
                            icon: 'assets/icon/calendar.svg',
                            label: 'Bookings',
                            isActive: _currentIndex == 1,
                            onTap: () => _navigateToPage(1),
                          )
                        : _DockNavBarChatItem(
                            isActive: _currentIndex == 1,
                            onTap: () => _navigateToPage(1),
                            showNotificationBadge: _usesNotificationsTab,
                          ),
                    _DockNavBarItem(
                      icon: _usesNotificationsTab
                          ? 'assets/icon/bell.svg'
                          : 'assets/icon/triangle-alert.svg',
                      label: _usesNotificationsTab ? 'Notifications' : 'Report',
                      isActive: _currentIndex == 2,
                      onTap: () => _navigateToPage(2),
                    ),
                    _DockNavBarItem(
                      icon: 'assets/icon/user-round.svg',
                      label: 'Profile',
                      isActive: _currentIndex == 3,
                      onTap: () => _navigateToPage(3),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Container(
                    height: 75,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1A5C2A),
                          Color(0xFF2A7D3A),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A5C2A).withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: DockNavBar(
                      items: [
                        _DockNavBarItem(
                          icon: 'assets/icon/house.svg',
                          label: 'Home',
                          isActive: _currentIndex == 0,
                          onTap: () => _navigateToPage(0),
                        ),
                        _DockNavBarChatItem(
                          isActive: _currentIndex == 1,
                          onTap: () => _navigateToPage(1),
                          showNotificationBadge: _usesNotificationsTab,
                        ),
                        _DockNavBarSpacerItem(),
                        _DockNavBarItem(
                          icon: 'assets/icon/triangle-alert.svg',
                          label: 'Report',
                          isActive: _currentIndex == 2,
                          onTap: () => _navigateToPage(2),
                        ),
                        _DockNavBarItem(
                          icon: 'assets/icon/user-round.svg',
                          label: 'Profile',
                          isActive: _currentIndex == 3,
                          onTap: () => _navigateToPage(3),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 35,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HoverableQRButton(
                        onTap: () => _navigateToPage(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Portal',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A5C2A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        // Modern Hero Card with Gradient and Animation
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A5C2A),
                        const Color(0xFF2A7D3A),
                        const Color(0xFF1A5C2A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A5C2A).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Animated Background Elements
                      Positioned(
                        right: -20,
                        top: -20,
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 2000),
                          curve: Curves.easeInOut,
                          builder: (context, val, _) {
                            return Transform.scale(
                              scale: 1 +
                                  (0.1 * ((val * 10).toInt().isEven ? 1 : -1)),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 30,
                        bottom: -30,
                        child: Container(
                          width: 80,
                          height: 80,
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
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5C518),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFF5C518).withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text(
                              'ANNOUNCEMENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Security desk briefing',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monitor access, visitors, and alerts from the cards below — same bottom menu as everyone.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/alerts'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5C518),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF5C518)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View alerts',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward,
                                      color: Colors.black, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),

        // Services Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'OUR SERVICES',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/access-control'),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF1A5C2A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Animated Service Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: List.generate(4, (index) {
            final cards = [
              {
                'icon': Icons.qr_code_scanner,
                'iconColor': const Color(0xFF5B8DEF),
                'title': 'Access',
                'subtitle': 'Grant & QR control',
                'route': '/access-control',
              },
              {
                'icon': Icons.people_outline,
                'iconColor': const Color(0xFFE07B3F),
                'title': 'Visitors',
                'subtitle': 'Guest management',
                'route': '/visitors',
              },
              {
                'icon': Icons.warning_amber_outlined,
                'iconColor': const Color(0xFFE05C8A),
                'title': 'Alerts',
                'subtitle': 'Incidents & notices',
                'route': '/alerts',
              },
              {
                'icon': Icons.history,
                'iconColor': const Color(0xFF9B59B6),
                'title': 'Access logs',
                'subtitle': 'Recent activity',
                'route': '/access-logs',
              },
            ];

            final card = cards[index];
            return _AnimatedServiceCard(
              delay: Duration(milliseconds: 100 * index),
              icon: card['icon'] as IconData,
              iconColor: card['iconColor'] as Color,
              title: card['title'] as String,
              subtitle: card['subtitle'] as String,
              onTap: () =>
                  Navigator.pushNamed(context, card['route'] as String),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Modern Info Card
        _AnimatedInfoCard(
          icon: Icons.security,
          title: 'Shift note',
          subtitle: 'Today • Security',
          buttonLabel: 'LOGS',
          content:
              'Check visitor queue and gate cameras during peak hours. Use Access for new entries.',
          onButtonTap: () => Navigator.pushNamed(context, '/access-logs'),
          delay: const Duration(milliseconds: 400),
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
        // Modern Hero Card
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A5C2A),
                        const Color(0xFF2A7D3A),
                        const Color(0xFF1A5C2A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A5C2A).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 30,
                        bottom: -30,
                        child: Container(
                          width: 80,
                          height: 80,
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
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5C518),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFF5C518).withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text(
                              'ANNOUNCEMENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Maintenance queue',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Open work orders and pending requests below — Home · Chat · Report · Profile stay the same.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/work-orders'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5C518),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF5C518)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Open work orders',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward,
                                      color: Colors.black, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),

        // Services Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'OUR SERVICES',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/schedule'),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF1A5C2A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Animated Service Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: List.generate(4, (index) {
            final cards = [
              {
                'icon': Icons.build_circle_outlined,
                'iconColor': const Color(0xFF5B8DEF),
                'title': 'Work orders',
                'subtitle': 'Active jobs',
                'route': '/work-orders',
              },
              {
                'icon': Icons.pending_actions_outlined,
                'iconColor': const Color(0xFFE07B3F),
                'title': 'Pending',
                'subtitle': 'Awaiting action',
                'route': '/pending-requests',
              },
              {
                'icon': Icons.calendar_today_outlined,
                'iconColor': const Color(0xFFE05C8A),
                'title': 'Schedule',
                'subtitle': 'Your calendar',
                'route': '/schedule',
              },
              {
                'icon': Icons.report_problem_outlined,
                'iconColor': const Color(0xFF9B59B6),
                'title': 'Report',
                'subtitle': 'Submit an issue',
                'route': '/report',
              },
            ];

            final card = cards[index];
            return _AnimatedServiceCard(
              delay: Duration(milliseconds: 100 * index),
              icon: card['icon'] as IconData,
              iconColor: card['iconColor'] as Color,
              title: card['title'] as String,
              subtitle: card['subtitle'] as String,
              onTap: () =>
                  Navigator.pushNamed(context, card['route'] as String),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Modern Info Card
        _AnimatedInfoCard(
          icon: Icons.build,
          title: 'Team note',
          subtitle: 'Today • Maintenance',
          buttonLabel: 'PENDING',
          content:
              'Prioritize common-area repairs before unit callbacks. Use Report in the bottom bar for new tickets.',
          onButtonTap: () => Navigator.pushNamed(context, '/pending-requests'),
          delay: const Duration(milliseconds: 400),
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
                      final result = await Navigator.pushNamed(
                          context, '/create-facility');
                      if (result == true) {
                        facilityProvider.fetchFacilities();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                  Navigator.pushNamed(context, '/facility-detail',
                      arguments: facility.id);
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
                                    child: const Icon(Icons.image,
                                        color: Colors.grey),
                                  );
                                },
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child:
                                    const Icon(Icons.image, color: Colors.grey),
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
                                const Icon(Icons.people,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Capacity: ${facility.capacity}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.access_time,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    facility.hours,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
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
    final List<Map<String, dynamic>> cards = [
      {
        'icon': Icons.support_agent,
        'iconColor': const Color(0xFF5B8DEF),
        'title': 'Helping Staff',
        'subtitle': 'Request cleaning, repair, or service',
        'route': '/helping-staff',
      },
      {
        'icon': Icons.event,
        'iconColor': const Color(0xFFE07B3F),
        'title': 'Events',
        'subtitle': 'Community gatherings & workshops',
        'route': '/events',
      },
      {
        'icon': Icons.qr_code_2_rounded,
        'iconColor': const Color(0xFF1A5C2A),
        'title': 'QR code',
        'subtitle': 'Generate Qr code for guests',
        'route': '/guest_qr',
      },
      {
        'icon': Icons.videocam,
        'iconColor': const Color(0xFFE05C8A),
        'title': 'Camera',
        'subtitle': 'View live camera feed',
        'route': '/camera-live',
      },
      {
        'icon': Icons.bolt,
        'iconColor': const Color(0xFFF5C518),
        'title': 'Energy Monitoring',
        'subtitle': 'Track your energy consumption',
        'route': '/monitoring',
      },
      {
        'icon': Icons.thermostat,
        'iconColor': const Color(0xFF00BCD4),
        'title': 'Temperature',
        'subtitle': 'Check room temperature',
        'route': '/temperature',
      },
      {
        'icon': Icons.feed,
        'iconColor': const Color(0xFF1A5C2A),
        'title': 'Feed',
        'subtitle': 'See community posts',
        'route': '/feed',
      },
      {
        'icon': Icons.place,
        'iconColor': const Color(0xFF9B59B6),
        'title': 'Facilities',
        'subtitle': 'Check available spaces & hours',
        'route': '/facilities',
      },
    ];

    bool showAll = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Hero Announcement Card (original style/animation)
            _BannerWithHover(
              title: 'Weekend Festival',
              subtitle:
                  'Join us this Saturday for the\ncommunity BBQ and music night.',
              hoverText: 'orelax your comfort home security and',
            ),
            const SizedBox(height: 28),

            // Resident shortcuts header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RESIDENT SERVICES',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => showAll = !showAll),
                  child: Text(
                    showAll ? 'Hide' : 'View All',
                    style: const TextStyle(
                      color: Color(0xFF1A5C2A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Resident Shortcut Grid with Animations (toggle all/first 4)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: List.generate(
                showAll ? cards.length : 4,
                (index) {
                  final card = cards[index];
                  return _AnimatedServiceCard(
                    delay: Duration(milliseconds: 80 * index),
                    icon: card['icon'] as IconData,
                    iconColor: card['iconColor'] as Color,
                    title: card['title'] as String,
                    subtitle: card['subtitle'] as String,
                    onTap: () =>
                        Navigator.pushNamed(context, card['route'] as String),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Community Post Card with Animation (real post placeholder)
            _AnimatedInfoCard(
              icon: Icons.people,
              title: 'Community Post',
              subtitle: '2 hours ago • General',
              buttonLabel: 'GO TO FEED',
              content:
                  '"Does anyone know a good local tutor for mathematics? My daughter needs some help with her finals..."',
              onButtonTap: () => Navigator.pushNamed(context, '/feed'),
              delay: const Duration(milliseconds: 400),
            ),

            const SizedBox(height: 100),
          ],
        );
      },
    );
  }
}

// ── Animated Chat Nav Item with Badge ──
class _AnimatedChatNavItem extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  final bool showNotificationBadge;

  const _AnimatedChatNavItem({
    required this.isActive,
    required this.onTap,
    required this.showNotificationBadge,
  });

  @override
  State<_AnimatedChatNavItem> createState() => _AnimatedChatNavItemState();
}

class _AnimatedChatNavItemState extends State<_AnimatedChatNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_AnimatedChatNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Chat',
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.1).animate(_controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? Colors.white.withOpacity(0.25)
                  : Colors.transparent,
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
                        widget.isActive ? Colors.white : Colors.white60,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (widget.isActive) ...[
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
                if (widget.showNotificationBadge)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red,
                            blurRadius: 4,
                          ),
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

class _HoverableQRButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverableQRButton({required this.onTap});

  @override
  State<_HoverableQRButton> createState() => _HoverableQRButtonState();
}

class _HoverableQRButtonState extends State<_HoverableQRButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isHovered ? 78 : 70,
          height: _isHovered ? 78 : 70,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF1A5C2A)
                  : const Color(0xFFE05C8A).withOpacity(0.5),
              width: _isHovered ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.3 : 0.2),
                blurRadius: _isHovered ? 20 : 15,
                offset: Offset(0, _isHovered ? 10 : 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: _isHovered ? 38 : 32,
              color: const Color(0xFF1A5C2A),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated Nav Item ──
class _AnimatedNavItem extends StatefulWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_AnimatedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.1).animate(_controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? Colors.white.withOpacity(0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  widget.icon,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    widget.isActive ? Colors.white : Colors.white60,
                    BlendMode.srcIn,
                  ),
                ),
                if (widget.isActive) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
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
      ),
    );
  }
}

// ── Modern Animated Service Card ──
class _AnimatedServiceCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Duration delay;

  const _AnimatedServiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<_AnimatedServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
          child: FadeTransition(
            opacity: _controller,
            child: Transform.scale(
              scale: _isHovered ? 1.05 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor
                          .withOpacity(_isHovered ? 0.25 : 0.08),
                      blurRadius: _isHovered ? 20 : 12,
                      offset: Offset(0, _isHovered ? 12 : 4),
                    ),
                  ],
                  border: Border.all(
                    color: _isHovered
                        ? widget.iconColor.withOpacity(0.2)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (widget.subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated Info Card ──
class _AnimatedInfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String content;
  final VoidCallback onButtonTap;
  final Duration delay;

  const _AnimatedInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.content,
    required this.onButtonTap,
    required this.delay,
  });

  @override
  State<_AnimatedInfoCard> createState() => _AnimatedInfoCardState();
}

class _AnimatedInfoCardState extends State<_AnimatedInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey[100]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5C2A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFF1A5C2A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onButtonTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A5C2A),
                            const Color(0xFF2A7D3A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A5C2A).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.buttonLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  widget.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
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

// ── Animated Icon Button ──
class _AnimatedIconButton extends StatefulWidget {
  final String icon;
  final String tooltip;
  final VoidCallback onTap;

  const _AnimatedIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.85).animate(_controller),
          child: SvgPicture.asset(
            widget.icon,
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated Profile Button ──
class _AnimatedProfileButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedProfileButton({required this.onTap});

  @override
  State<_AnimatedProfileButton> createState() => _AnimatedProfileButtonState();
}

class _AnimatedProfileButtonState extends State<_AnimatedProfileButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profile',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.85).animate(_controller),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _BannerWithHover extends StatefulWidget {
  final String title;
  final String subtitle;
  final String hoverText;

  const _BannerWithHover({
    required this.title,
    required this.subtitle,
    required this.hoverText,
  });

  @override
  State<_BannerWithHover> createState() => _BannerWithHoverState();
}

class _BannerWithHoverState extends State<_BannerWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHovered
                ? [const Color(0xFF1A5C2A), const Color(0xFF2E7D32)]
                : [
                    const Color(0xFF1A5C2A),
                    const Color(0xFF2A7D3A),
                    const Color(0xFF1A5C2A)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0xFF1A5C2A).withOpacity(_isHovered ? 0.3 : 0.2),
              blurRadius: _isHovered ? 25 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 4 Floating Circles - Kept and slowed down
            ...List.generate(4, (index) {
              final positions = [
                const Offset(-20, -20),
                const Offset(30, -30),
                const Offset(-10, 50),
                const Offset(100, 20),
              ];
              final sizes = [100.0, 80.0, 60.0, 120.0];
              return Positioned(
                right: positions[index].dx,
                top: positions[index].dy,
                child: _FloatingCircle(
                  size: sizes[index],
                  color: Colors.white.withOpacity(0.08),
                  duration: Duration(seconds: 8 + index * 2), // Slow motion
                ),
              );
            }),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isHovered
                  ? Center(
                      key: const ValueKey('hoverContent'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Orelax Real Estate",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF5C518),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Your comfort, our priority. A secure and peaceful home for your family's brightest future.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      key: const ValueKey('normalContent'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5C518),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ANNOUNCEMENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5C518),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Learn More',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward,
                                  color: Colors.black, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
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

// ── Dock Nav Bar Item ──
abstract class _DockNavBarItemBase {
  const _DockNavBarItemBase();
}

class _DockNavBarItem extends _DockNavBarItemBase {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DockNavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
}

class _DockNavBarChatItem extends _DockNavBarItemBase {
  final bool isActive;
  final VoidCallback onTap;
  final bool showNotificationBadge;

  const _DockNavBarChatItem({
    required this.isActive,
    required this.onTap,
    required this.showNotificationBadge,
  });
}

class _DockNavBarSpacerItem extends _DockNavBarItemBase {
  const _DockNavBarSpacerItem();
}

// ── Dock Navigation Bar with Magnification Animation ──
class DockNavBar extends StatefulWidget {
  final List<_DockNavBarItemBase> items;

  const DockNavBar({
    required this.items,
  });

  @override
  State<DockNavBar> createState() => _DockNavBarState();
}

class _DockNavBarState extends State<DockNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _scaleControllers;

  @override
  void initState() {
    super.initState();
    _scaleControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleItemTap(int index, _DockNavBarItemBase item) {

    // Trigger magnification animation on tapped item
    _scaleControllers[index].forward().then((_) {
      if (mounted) {
        _scaleControllers[index].reverse();
      }
    });

    // Trigger neighbor magnification animations
    for (int i = 0; i < _scaleControllers.length; i++) {
      if (i != index) {
        final distance = (i - index).abs();
        if (distance <= 2) {
          final neighborScale = 1.0 - (distance * 0.15);
          _scaleControllers[i]
              .forward(from: 1.0 - (neighborScale - 1.0) * 0.6)
              .then((_) {
            if (mounted) {
              _scaleControllers[i].reverse();
            }
          });
        }
      }
    }

    // Execute the tap callback
    if (item is _DockNavBarItem) {
      item.onTap();
    } else if (item is _DockNavBarChatItem) {
      item.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(widget.items.length, (index) {
        final item = widget.items[index];

        if (item is _DockNavBarSpacerItem) {
          return const SizedBox(width: 60);
        }

        if (item is _DockNavBarChatItem) {
          return _DockMagnifiedChatItem(
            item: item,
            scaleController: _scaleControllers[index],
            onTap: () => _handleItemTap(index, item),
          );
        }

        if (item is _DockNavBarItem) {
          return _DockMagnifiedItem(
            item: item,
            scaleController: _scaleControllers[index],
            onTap: () => _handleItemTap(index, item),
          );
        }

        return const SizedBox.shrink();
      }),
    );
  }
}

// ── Dock Magnified Item ──
class _DockMagnifiedItem extends StatelessWidget {
  final _DockNavBarItem item;
  final AnimationController scaleController;
  final VoidCallback onTap;

  const _DockMagnifiedItem({
    required this.item,
    required this.scaleController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: item.label,
        child: AnimatedBuilder(
          animation: scaleController,
          builder: (context, _) {
            final progress = scaleController.value;
            final scale = 1.0 + (0.25 * progress);

            return Transform.scale(
              scale: scale,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: item.isActive
                      ? Colors.white.withOpacity(0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      item.icon,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        item.isActive
                            ? Colors.white
                            : Colors.white60,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (item.isActive) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.label,
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
            );
          },
        ),
      ),
    );
  }
}

// ── Dock Magnified Chat Item ──
class _DockMagnifiedChatItem extends StatelessWidget {
  final _DockNavBarChatItem item;
  final AnimationController scaleController;
  final VoidCallback onTap;

  const _DockMagnifiedChatItem({
    required this.item,
    required this.scaleController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: 'Chat',
        child: AnimatedBuilder(
          animation: scaleController,
          builder: (context, _) {
            final progress = scaleController.value;
            final scale = 1.0 + (0.25 * progress);

            return Transform.scale(
              scale: scale,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: item.isActive
                      ? Colors.white.withOpacity(0.25)
                      : Colors.transparent,
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
                            item.isActive
                                ? Colors.white
                                : Colors.white60,
                            BlendMode.srcIn,
                          ),
                        ),
                        if (item.isActive) ...[
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
                    if (item.showNotificationBadge)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
          },
        ),
      ),
    );
  }
}
