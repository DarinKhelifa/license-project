import 'package:flutter/material.dart';

class HomeTopBar extends StatelessWidget {
  final String tagline;
  final VoidCallback? onCameraTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const HomeTopBar({super.key, this.tagline = '', this.onCameraTap, this.onNotificationsTap, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: Text(tagline, style: const TextStyle(fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: onCameraTap),
          IconButton(icon: const Icon(Icons.notifications), onPressed: onNotificationsTap),
          GestureDetector(onTap: onProfileTap, child: const CircleAvatar(radius: 16, child: Icon(Icons.person))),
        ],
      ),
    );
  }
}
