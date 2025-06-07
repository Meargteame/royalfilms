// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/tv_series_screen.dart';
import 'screens/payment_test_screen.dart';
import 'config/app_theme.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully");
  } catch (e) {
    // Handle .env loading errors gracefully
    print("Warning: Could not load .env file: $e");
    // Continue anyway as we have hardcoded defaults in ChapaConfig
  }
  
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
    
    // Initialize connection to WebSocket with error handling
    try {
      if (!kIsWeb) {
        // Only try WebSocket connection in non-web environments
        _apiService.connectToContentWebSocket(type: 'featured');
      } else {
        print('WebSocket connection skipped in web environment');
      }
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      // Continue without WebSocket connection
    }
  }
  
  void _initializeScreens() {
    _screens = [
      HomeScreen(apiService: _apiService, localStorageService: _localStorageService),
      MoviesScreen(apiService: _apiService, localStorageService: _localStorageService),
      TvSeriesScreen(apiService: _apiService, localStorageService: _localStorageService),
      DownloadsScreen(apiService: _apiService, localStorageService: _localStorageService),
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
            icon: Icon(Icons.download_outlined),
            label: 'Downloads',
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
