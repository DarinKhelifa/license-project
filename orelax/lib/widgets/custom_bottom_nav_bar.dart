import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    String routeName = '/';
    switch (index) {
      case 0:
        routeName = '/home';
        break;
      case 1:
        routeName = '/booking-history';
        break;
      case 2:
        routeName = '/chat';
        break;
      case 3:
        routeName = '/profile';
        break;
    }

    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              isActive: currentIndex == 0,
              onTap: () => _onItemTapped(context, 0),
            ),
            _NavItem(
              icon: 'assets/icon/handshake.svg',
              label: 'Booking',
              isActive: currentIndex == 1,
              onTap: () => _onItemTapped(context, 1),
            ),
            _ChatNavItem(
              isActive: currentIndex == 2,
              onTap: () => _onItemTapped(context, 2),
            ),
            _NavItem(
              icon: 'assets/icon/user-round.svg',
              label: 'Profile',
              isActive: currentIndex == 3,
              onTap: () => _onItemTapped(context, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _ChatNavItem({
    required this.isActive,
    required this.onTap,
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
            color:
                isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
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
            ],
          ),
        ),
      ),
    );
  }
}

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
