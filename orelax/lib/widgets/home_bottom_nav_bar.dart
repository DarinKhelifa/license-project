import 'package:flutter/material.dart';
import 'custom_bottom_nav_bar.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final bool isFacilitiesManager;
  final bool usesNotificationsTab;

  const HomeBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.isFacilitiesManager = false,
    this.usesNotificationsTab = false,
  });

  @override
  Widget build(BuildContext context) {
    // Delegate to existing CustomBottomNavBar (navigation handled internally there)
    return CustomBottomNavBar(currentIndex: currentIndex);
  }
}
