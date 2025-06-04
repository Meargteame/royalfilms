// lib/main.dart
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/watch_list_screen.dart';
import 'screens/tv_series_screen.dart';
import 'config/app_theme.dart';

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
  final ApiService _apiService = ApiService();
  final LocalStorageService _localStorageService = LocalStorageService();
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    // Initialize connection to WebSocket
    _apiService.connectToContentWebSocket(type: 'featured');
  }
  
  void _initializeScreens() {
    _screens = [
      HomeScreen(apiService: _apiService, localStorageService: _localStorageService),
      MoviesScreen(localStorageService: _localStorageService),
      TvSeriesScreen(apiService: _apiService, localStorageService: _localStorageService),
      WatchListScreen(apiService: _apiService, localStorageService: _localStorageService),
      SettingsScreen(apiService: _apiService, localStorageService: _localStorageService),
    ];
  }

  @override
  void dispose() {
    _apiService.dispose();
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
