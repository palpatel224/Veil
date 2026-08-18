import 'package:flutter/material.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'private_pilot_screen.dart';
import 'programs_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PrivatePilotScreen(),
    const ProgramsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
        color: Colors.black, // Match Scaffold background
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.grid_view_rounded),
            _buildNavItem(1, Icons.auto_awesome),
            _buildNavItem(2, Icons.storefront_outlined),
            _buildNavItem(3, Icons.person_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12) : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white70,
          size: 24,
        ),
      ),
    );
  }
}
