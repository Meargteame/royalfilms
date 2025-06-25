// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';
import 'config/app_theme.dart';
// Main navigation screens
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/tv_series_screen.dart';
// Additional screens that can be navigated to
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/filter_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/payment_screen.dart';

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
    final ApiService apiService = ApiService();
    final LocalStorageService localStorageService = LocalStorageService();

    return MaterialApp(
      title: 'EthioNetflix',
      theme: AppTheme.darkTheme,
      home: MainScreen(apiService: apiService, localStorageService: localStorageService),
      routes: {
        '/payment': (context) => PaymentScreen(
              amount: 9.99, // Default amount for a subscription
              movieTitle: "Monthly Subscription",
              onPaymentComplete: (success) {
                if (success) {
                  // Optionally navigate to a success screen or back home
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  // Optionally show a failure message
                }
              },
            ),
        '/subscription': (context) => SubscriptionScreen(
            apiService: apiService,
            localStorageService: localStorageService,
        ),
        '/search': (context) => SearchScreen(
              apiService: apiService,
              localStorageService: localStorageService,
            ),
        '/profile': (context) => const ProfileScreen(),
        '/filter': (context) => FilterScreen(
              apiService: apiService,
            ),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final ApiService apiService;
  final LocalStorageService localStorageService;

  const MainScreen({
    super.key,
    required this.apiService,
    required this.localStorageService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final ApiService _apiService;
  late final LocalStorageService _localStorageService;
  
  late final List<Widget> _screens;
  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _localStorageService = widget.localStorageService;
    _initializeScreens();
    
    // Initialize connection to WebSocket with error handling
    try {
      if (!kIsWeb) {
        // Only try WebSocket connection in non-web environments
        _apiService.connectToContentWebSocket(
          type: 'all',
          limit: 1, // Minimal request to establish connection
        ).listen((data) {
            // We don't need to process data here, just confirm connection
            print('WebSocket connection established in main');
        }, onError: (error) {
            print('WebSocket connection error in main: $error');
        });
      }
    } catch (e) {
      print('Failed to initialize WebSocket connection in main: $e');
    }
  }

  void _initializeScreens() {
    _screens = [
      HomeScreen(
        apiService: _apiService,
        localStorageService: _localStorageService,
      ),
      MoviesScreen(
        apiService: _apiService,
        localStorageService: _localStorageService,
      ),
      TvSeriesScreen(
        apiService: _apiService,
        localStorageService: _localStorageService,
      ),
      DownloadsScreen(
        apiService: _apiService,
        localStorageService: _localStorageService,
      ),
      SettingsScreen(
        apiService: _apiService,
        localStorageService: _localStorageService,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tv),
            label: 'TV Series',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: AppTheme.backgroundColor, // Changed from navBarColor
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
