import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──
              const Center(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Profile Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: const AssetImage('assets/images/introImg.png'),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 16),
                    // Name & email
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khiri Soudnous',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'khiri.soudnous@gmail.com',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
                    _ProfileTile(icon: Icons.person_outline, title: 'Edit Profile'),
                    _divider(),
                    _ProfileTile(icon: Icons.shield_outlined, title: 'Password & Security'),
                    _divider(),
                    _ProfileTile(icon: Icons.notifications_outlined, title: 'Notifications'),
                    _divider(),
                    _ProfileTile(icon: Icons.notifications_outlined, title: 'Alerts'),
                    _divider(),
                    _ProfileTile(
                      icon: Icons.grid_view_outlined,
                      title: 'Language',
                      trailing: 'English',
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
                    _ProfileTile(icon: Icons.shield_outlined, title: 'About Us'),
                    _divider(),
                    _ProfileTile(
                      icon: Icons.grid_view_outlined,
                      title: 'Theme',
                      trailing: 'Light',
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
                      icon: Icons.chat_bubble_outline,
                      title: 'Help Center',
                    ),
                    _divider(),
                    _ProfileTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      titleColor: Colors.red,
                      iconColor: Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
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

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.titleColor = Colors.black87,
    this.iconColor = Colors.black54,
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
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
      onTap: () {},
    );
  }
}