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
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.mutedGrey, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded, color: AppColors.secondaryAccent),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              activeIcon: Icon(Icons.auto_awesome, color: AppColors.secondaryAccent),
              label: 'PrivatePilot',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.layers_outlined),
              activeIcon: Icon(Icons.layers, color: AppColors.secondaryAccent),
              label: 'Programs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppColors.secondaryAccent),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
