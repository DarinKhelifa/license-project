import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: const AssetImage('assets/images/introImg.png'),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 16),
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
                    _ProfileTile(
                      icon: SvgPicture.asset('assets/icon/user-pen.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn)),
                      title: 'Edit Profile'),
                    _divider(),
                    _ProfileTile(
                      icon: SvgPicture.asset('assets/icon/shield-check.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn)),
                      title: 'Privacy'),
                    _divider(),
                    _ProfileTile(
                      icon: SvgPicture.asset('assets/icon/bell.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn)),
                      title: 'Notifications'),
                    _divider(),
                    _ProfileTile(
                      icon: SvgPicture.asset('assets/icon/triangle-alert.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn)),
                      title: 'Alerts'),
                    _divider(),
                    _ProfileTile(
                      icon: SvgPicture.asset('assets/icon/languages.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn)),
                      title: 'Language',
                      trailing: 'English'),
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
                      icon: SvgPicture.asset('assets/icon/handshake.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn)),
                      title: 'About Us'),
                    _divider(),
                    _ProfileTile(
                      icon: SvgPicture.asset('assets/icon/moon.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn)),
                      title: 'Theme',
                      trailing: 'Light'),
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
                      icon: SvgPicture.asset('assets/icon/message-circle-question-mark.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn)),
                      title: 'Contact Us'),
                    _divider(),
                    _ProfileTile(
                      icon: SvgPicture.asset('assets/icon/triangle-alert.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn)),
                      title: 'Help Center'),
                    _divider(),
                    _ProfileTile(
                      icon: SvgPicture.asset('assets/icon/log-out.svg', width: 22, height: 22,
                        colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn)),
                      title: 'Logout',
                      titleColor: Colors.red),
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
  final Widget icon;
  final String title;
  final String? trailing;
  final Color titleColor;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.titleColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
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