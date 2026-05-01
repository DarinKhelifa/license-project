import 'package:flutter/material.dart';
import 'package:orelax/widgets/custom_bottom_nav_bar.dart';

class MaintenanceScheduleScreen extends StatelessWidget {
  const MaintenanceScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      appBar: AppBar(title: const Text('Maintenance Schedule')),
      body: const Center(child: Text('Maintenance Schedule - Coming soon')),
    );
  }
}

