// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/logo.dart';
import 'tv_login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulate user data - In a real app, this would come from a user service
    final Map<String, dynamic> userData = {
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'profileImage': null, // Placeholder for profile image
      'watchList': 12,
      'history': 34,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: AppTheme.textColorPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.textColorPrimary),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.backgroundColor,
                    backgroundImage: userData['profileImage'] != null
                        ? NetworkImage(userData['profileImage'])
                        : null,
                    child: userData['profileImage'] == null
                        ? const Icon(Icons.person, size: 40, color: AppTheme.textColorSecondary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userData['email'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.textColorSecondary),
                    onPressed: () {
                      // Edit profile
                    },
                  ),
                ],
              ),
            ),

            // Options Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Watch List
                  ListTile(
                    leading: const Icon(Icons.bookmark, color: AppTheme.primaryColor),
                    title: const Text('My List', style: TextStyle(color: AppTheme.textColorPrimary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${userData['watchList']} items',
                          style: const TextStyle(color: AppTheme.textColorSecondary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppTheme.textColorSecondary),
                      ],
                    ),
                    onTap: () {
                      // Navigate to watch list
                    },
                  ),
                  
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.dividerColor),

                  // History
                  ListTile(
                    leading: const Icon(Icons.history, color: AppTheme.primaryColor),
                    title: const Text('History', style: TextStyle(color: AppTheme.textColorPrimary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${userData['history']} items',
                          style: const TextStyle(color: AppTheme.textColorSecondary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppTheme.textColorSecondary),
                      ],
                    ),
                    onTap: () {
                      // Navigate to history
                    },
                  ),
                  
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.dividerColor),
                  
                  // TV Login
                  ListTile(
                    leading: const Icon(Icons.tv, color: AppTheme.primaryColor),
                    title: const Text('TV Login', style: TextStyle(color: AppTheme.textColorPrimary)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textColorSecondary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TvLoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Subscription Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Premium Plan',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Valid until June 30, 2025',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Renew subscription
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppTheme.buttonTextColor,
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Renew Subscription'),
                    ),
                  ),
                ],
              ),
            ),
            
            // Logout Button
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Handle logout
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textColorPrimary,
                  side: const BorderSide(color: AppTheme.textColorSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Log out'),
              ),
            ),
            
            // App Info
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const AppLogo(width: 120, height: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(color: AppTheme.textColorTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
