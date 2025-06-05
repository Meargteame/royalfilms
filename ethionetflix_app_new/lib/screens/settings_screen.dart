// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/logo.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

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
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checking for updates (dummy)...'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
              child: const Text(
                'Check for Updates',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
