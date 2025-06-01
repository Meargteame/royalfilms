// lib/main.dart
import 'package:flutter/material.dart';
// import 'services/api_service.dart'; // Removed
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
// import 'screens/login_screen.dart'; // Removed
// import 'screens/tv_login_screen.dart'; // Removed
import 'screens/movies_screen.dart';
import 'screens/watch_list_screen.dart';
import 'screens/tv_series_screen.dart';
import 'config/app_theme.dart';
// import 'screens/backend_test_screen.dart'; // Removed
// import 'screens/websocket_test_screen.dart'; // Removed

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EthioNetflix',
      theme: AppTheme.darkTheme,
      home: const MainScreen(), // Set MainScreen back as home
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  // final ApiService _apiService = ApiService(); // Removed

  final List<Widget> _screens = [
    const HomeScreen(),
    const MoviesScreen(),
    const TvSeriesScreen(),
    const WatchListScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // _apiService.connectToContentWebSocket(); // Removed
  }

  @override
  void dispose() {
    // _apiService.dispose(); // Removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'TV Series',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border_outlined),
            label: 'Watch List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textColorSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textColorSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textColorSecondary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
