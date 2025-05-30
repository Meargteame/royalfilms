// lib/main.dart
import 'package:flutter/material.dart';
import 'package:royalfilms/services/mock_data_service.dart'; // Using mock instead of api_service
import 'package:royalfilms/screens/home_screen.dart';
import 'package:royalfilms/screens/search_screen.dart';
import 'package:royalfilms/screens/profile_screen.dart';
import 'package:royalfilms/screens/settings_screen.dart';
import 'package:royalfilms/screens/login_screen.dart';
import 'package:royalfilms/screens/tv_login_screen.dart';
import 'package:royalfilms/screens/movies_screen.dart';
import 'package:royalfilms/screens/watch_list_screen.dart';
import 'package:royalfilms/screens/tv_series_screen.dart';
import 'package:royalfilms/config/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoyalFilms',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppTheme.primaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppTheme.textColorPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppTheme.textColorPrimary),
        ),
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.buttonTextColor,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: AppTheme.surfaceColor,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: AppTheme.textColorTertiary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppTheme.backgroundColor,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textColorSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textColorSecondary,
          indicatorColor: AppTheme.primaryColor,
        ),
        dividerTheme: const DividerThemeData(
          color: AppTheme.dividerColor,
          thickness: 1,
          space: 1,
        ),
      ),
      home: const MainScreen(),
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
  final MockDataService _mockService = MockDataService();

  final List<Widget> _screens = [
    const HomeScreen(), // index 0 (Home)
    const MoviesScreen(), // index 1 (Movies) - now points to MoviesScreen
    const TvSeriesScreen(), // index 2 (TV Series) - now points to TvSeriesScreen
    const WatchListScreen(), // index 3 (Watch List) - now points to WatchListScreen
    const SettingsScreen(), // index 4 (More) - remains SettingsScreen
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the mock service when the app starts
    _mockService.init();
  }

  @override
  void dispose() {
    _mockService.dispose(); // Clean up resources
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
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
              color:
                  isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textColorSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    isSelected
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
