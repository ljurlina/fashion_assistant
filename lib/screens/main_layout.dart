import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'home/closet_screen.dart';
import 'home/scan_intent_screen.dart';
import 'profile/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ClosetScreen(),
    const ScanIntentScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: _screens[_currentIndex],
      bottomNavigationBar: Material(
        color: AppColors.cream,
        child: SafeArea(
          child: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(96, 10, 96, 12),
      child: SizedBox(
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE6D6),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSideNavItem(icon: Icons.checkroom_outlined, index: 0),
                    const SizedBox(width: 70),
                    _buildSideNavItem(icon: Icons.person_outline, index: 2),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9D2BF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.crop_free,
                  color: _currentIndex == 1
                      ? const Color(0xFF7A7260)
                      : const Color(0xFFB2AA98),
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNavItem({required IconData icon, required int index}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9D2BF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF7A7260)
                  : const Color(0xFFB2AA98),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}