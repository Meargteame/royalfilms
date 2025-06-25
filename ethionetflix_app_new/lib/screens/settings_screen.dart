// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../widgets/logo.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
// import 'payment_test_screen.dart';
import 'subscription_screen.dart';
// import 'download_test_screen.dart'; // Commented out as per the suggestion

class SettingsScreen extends StatelessWidget {
  final ApiService? apiService;
  final LocalStorageService? localStorageService;
  
  const SettingsScreen({
    super.key, 
    this.apiService,
    this.localStorageService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(width: 200, height: 60), // Larger logo
            const SizedBox(height: 16),
            Text(
              'Your ultimate streaming destination',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2025 All rights reserved.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColorSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'App Version: 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColorSecondary,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Subscription Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionScreen(
                      apiService: apiService,
                      localStorageService: localStorageService,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Manage Subscription'),
            ),
            
            // Only show Test Payment button in web mode
            /* if (kIsWeb) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentTestScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Test Payment (Web Only)'),
              ),
            ], */
            
            // Add Modern Download Test button for all platforms
            /* const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DownloadTestScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Test Modern Downloads'),
            ), */
          ],
        ),
      ),
    );
  }
}
