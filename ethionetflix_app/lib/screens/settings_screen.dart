// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/logo.dart';
import 'tv_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _enableNotifications = true;
  bool _autoPlay = true;
  String _selectedQuality = 'Auto';
  String _selectedSubtitleLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // App Preferences Section
          _buildSectionHeader('App Preferences'),
          SwitchListTile(
            title: const Text('Dark Mode', style: TextStyle(color: AppTheme.textColorPrimary)),
            subtitle: const Text(
              'Enable dark theme for the app',
              style: TextStyle(color: AppTheme.textColorSecondary),
            ),
            value: _darkMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Notifications', style: TextStyle(color: AppTheme.textColorPrimary)),
            subtitle: const Text(
              'Receive notifications about new content',
              style: TextStyle(color: AppTheme.textColorSecondary),
            ),
            value: _enableNotifications,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() {
                _enableNotifications = value;
              });
            },
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // Playback Preferences Section
          _buildSectionHeader('Playback Preferences'),
          SwitchListTile(
            title: const Text('Auto Play', style: TextStyle(color: AppTheme.textColorPrimary)),
            subtitle: const Text(
              'Automatically play next episode',
              style: TextStyle(color: AppTheme.textColorSecondary),
            ),
            value: _autoPlay,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() {
                _autoPlay = value;
              });
            },
          ),
          ListTile(
            title: const Text('Video Quality', style: TextStyle(color: AppTheme.textColorPrimary)),
            subtitle: Text(
              _selectedQuality,
              style: const TextStyle(color: AppTheme.textColorSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textColorSecondary),
            onTap: () {
              _showQualityPicker();
            },
          ),
          ListTile(
            title: const Text('Subtitle Language', style: TextStyle(color: AppTheme.textColorPrimary)),
            subtitle: Text(
              _selectedSubtitleLanguage,
              style: const TextStyle(color: AppTheme.textColorSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textColorSecondary),
            onTap: () {
              _showSubtitleLanguagePicker();
            },
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // Account Section
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.tv, color: AppTheme.primaryColor),
            title: const Text('TV Login', style: TextStyle(color: AppTheme.textColorPrimary)),
            subtitle: const Text(
              'Connect with your TV using a code',
              style: TextStyle(color: AppTheme.textColorSecondary),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TvLoginScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppTheme.primaryColor),
            title: const Text('Clear Watch History', style: TextStyle(color: AppTheme.textColorPrimary)),
            subtitle: const Text(
              'Remove all items from your watch history',
              style: TextStyle(color: AppTheme.textColorSecondary),
            ),
            onTap: () {
              _showClearHistoryConfirmation();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.primaryColor),
            title: const Text('Sign Out', style: TextStyle(color: AppTheme.textColorPrimary)),
            onTap: () {
              _showSignOutConfirmation();
            },
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // About Section
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('App Version', style: TextStyle(color: AppTheme.textColorPrimary)),
            subtitle: const Text(
              '1.0.0',
              style: TextStyle(color: AppTheme.textColorSecondary),
            ),
          ),
          ListTile(
            title: const Text('Terms of Service', style: TextStyle(color: AppTheme.textColorPrimary)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textColorSecondary),
            onTap: () {
              // Show terms of service
            },
          ),
          ListTile(
            title: const Text('Privacy Policy', style: TextStyle(color: AppTheme.textColorPrimary)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textColorSecondary),
            onTap: () {
              // Show privacy policy
            },
          ),
          // App Logo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  const AppLogo(width: 120, height: 36),
                  const SizedBox(height: 8),
                  Text(
                    '© 2025 EthioNetflix. All rights reserved.',
                    style: TextStyle(color: AppTheme.textColorTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Video Quality',
                  style: TextStyle(
                    color: AppTheme.textColorPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.dividerColor),
              for (final quality in ['Auto', 'Low', 'Medium', 'High', '4K'])
                ListTile(
                  title: Text(quality, style: const TextStyle(color: AppTheme.textColorPrimary)),
                  trailing: _selectedQuality == quality
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedQuality = quality;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showSubtitleLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Subtitle Language',
                  style: TextStyle(
                    color: AppTheme.textColorPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.dividerColor),
              for (final language in ['English', 'Spanish', 'French', 'Arabic', 'Amharic'])
                ListTile(
                  title: Text(language, style: const TextStyle(color: AppTheme.textColorPrimary)),
                  trailing: _selectedSubtitleLanguage == language
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedSubtitleLanguage = language;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showClearHistoryConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Clear Watch History?', style: TextStyle(color: AppTheme.textColorPrimary)),
        content: const Text(
          'This will remove all items from your watch history. This action cannot be undone.',
          style: TextStyle(color: AppTheme.textColorSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textColorSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear watch history logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: AppTheme.buttonTextColor,
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Sign Out?', style: TextStyle(color: AppTheme.textColorPrimary)),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: AppTheme.textColorSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textColorSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Sign out logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: AppTheme.buttonTextColor,
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
