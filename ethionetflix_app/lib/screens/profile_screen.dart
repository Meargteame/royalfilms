// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Removed actual logout logic
              print('Dummy Logout: User would be logged out here.');
              Navigator.pop(context); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You have been logged out (dummy).'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppTheme.textColorPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            _buildProfileHeader(
              'Dummy User',
              'dummy.user@example.com',
              'https://via.placeholder.com/150?text=User',
            ),
            const SizedBox(height: 24),

            // Account Settings
            _buildProfileOption(
              icon: Icons.subscriptions_outlined,
              title: 'Subscription',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Logout Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context), // Use dummy logout
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppTheme.buttonTextColor,
                  backgroundColor: AppTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String imageUrl) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage(imageUrl),
          backgroundColor: AppTheme.surfaceColor,
          onBackgroundImageError: (_, __) {},
          child: const Icon(Icons.person,
              size: 40, color: AppTheme.textColorSecondary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: AppTheme.textColorPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                color: AppTheme.textColorSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppTheme.primaryColor),
          title: Text(
            title,
            style:
                const TextStyle(color: AppTheme.textColorPrimary, fontSize: 16),
          ),
          trailing: const Icon(Icons.chevron_right,
              color: AppTheme.textColorSecondary),
          onTap: onTap,
        ),
        const Divider(color: AppTheme.surfaceColor, height: 1),
      ],
    );
  }
}
