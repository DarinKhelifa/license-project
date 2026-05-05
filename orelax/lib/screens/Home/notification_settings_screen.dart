import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  static const String _prefKey = 'notifications_enabled';

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_prefKey) ?? true;
    });
  }

  Future<void> _setPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    setState(() => _notificationsEnabled = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Notifications turned ON' : 'Notifications turned OFF', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: value ? const Color(0xFF1A5C2A) : Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkGreen),
      ),
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_outlined, color: darkGreen),
                    title: Text('App Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text('Allow ORELAX to send you notifications and alerts', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeColor: darkGreen,
                      onChanged: (v) => _setPreference(v),
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
