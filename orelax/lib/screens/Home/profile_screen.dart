import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../screens/Welcome/welcome_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'contact_us_screen.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = await authProvider.getUserData();

    setState(() {
      _userData = userData;
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    const Color darkGreen = Color(0xFF1A5C2A);
    const Color lightGreen = Color(0xFFE8F5E9);

    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A5C2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Profile Card ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // Avatar with image or initials
                      _buildProfileAvatar(_userData, user),
                      const SizedBox(width: 16),
                      // Name & email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userData?['name'] ?? user?['name'] ?? 'Loading...',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _userData?['email'] ?? user?['email'] ?? 'No email',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── ACCOUNT Section ──
                const _SectionLabel(label: 'ACCOUNT'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: () => _navigateToEditProfile(),
                      ),
                      _divider(),
                      _ProfileTile(
                        icon: Icons.shield_outlined,
                        title: 'Password & Security',
                        onTap: () => _navigateToChangePassword(),
                      ),
                      _divider(),
                      _ProfileTile(
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        trailing: _userData?['phone'] ?? 'Not set',
                        onTap: () => _editPhoneNumber(),
                      ),
                      _divider(),

                      _ProfileTile(
                        icon: Icons.badge_outlined,
                        title: 'Role',
                        trailing: _userData?['role']?.toString().toUpperCase() ?? 'Resident',
                        onTap: null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── PREFERENCES Section ──
                const _SectionLabel(label: 'PREFERENCES'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.info_outline,
                        title: 'About Us',
                        onTap: () => _showAboutDialog(),
                      ),
                      _divider(),
                      _ProfileTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        trailing: 'On',
                        onTap: () => _toggleNotifications(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── SUPPORT Section ──
                const _SectionLabel(label: 'SUPPORT'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                        onTap: () => _showHelpCenter(),
                      ),
                      _divider(),
                      _ProfileTile(
                        icon: Icons.contact_mail_outlined,
                        title: 'Contact Us',
                        onTap: () => _navigateToContactUs(),
                      ),
                      _divider(),
                      _ProfileTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        titleColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic>? userData, Map<String, dynamic>? user) {
    const Color darkGreen = Color(0xFF1A6B2F);
    
    // Check if profile image exists
    final profileImage = userData?['profileImage'] ?? user?['profileImage'];
    
    if (profileImage != null && profileImage.toString().isNotEmpty) {
      // Display network image if available
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(profileImage),
        backgroundColor: Colors.grey.shade300,
      );
    } else {
      // Fall back to initials
      return CircleAvatar(
        radius: 36,
        backgroundColor: darkGreen,
        child: Text(
          _getInitials(userData?['name'] ?? user?['name'] ?? 'U'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  void _navigateToChangePassword() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  void _navigateToContactUs() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactUsScreen(),
      ),
    );
  }

  void _editPhoneNumber() async {
    final TextEditingController controller = TextEditingController(
      text: _userData?['phone'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter phone number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.updateUserData({
                  'phone': controller.text,
                });
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B2F),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  void _editApartment() async {
    final TextEditingController controller = TextEditingController(
      text: _userData?['apartment'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Apartment Number'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter apartment number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.updateUserData({
                  'apartment': controller.text,
                });
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B2F),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ORELAX'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Smart Residential Community Management'),
            SizedBox(height: 8),
            Text('© 2024 ORELAX. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleNotifications() {
    // TODO: Implement notification toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHelpCenter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 8),
            Text('Email: support@orelax.com'),
            Text('Phone: +213 (0) 123 456 789'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.signOut();
              Navigator.pop(dialogContext); // Close dialog
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const WelcomeScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 56,
    );
  }
}

// ── Section Label ──
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Profile Tile ──
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Color titleColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.titleColor = Colors.black87,
    this.iconColor = Colors.black54,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          if (onTap != null) const SizedBox(width: 4),
          if (onTap != null)
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}