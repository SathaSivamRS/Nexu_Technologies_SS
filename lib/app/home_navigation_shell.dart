import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../features/about/presentation/screens/about_screen.dart';
import '../features/route_management/presentation/screens/dashboard_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/summary/presentation/screens/daily_summary_screen.dart';

class HomeNavigationShell extends StatefulWidget {
  const HomeNavigationShell({super.key});

  @override
  State<HomeNavigationShell> createState() => _HomeNavigationShellState();
}

class _HomeNavigationShellState extends State<HomeNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    DailySummaryScreen(),
    SettingsScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryNavy.withAlpha(25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded, color: AppTheme.primaryNavy),
            label: 'Route',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon:
                Icon(Icons.assessment_rounded, color: AppTheme.primaryNavy),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon:
                Icon(Icons.settings_rounded, color: AppTheme.primaryNavy),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline_rounded),
            selectedIcon: Icon(Icons.info_rounded, color: AppTheme.primaryNavy),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
