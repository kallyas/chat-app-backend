import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: themeProvider.surfaceColor,
            elevation: 0,
          ),
          body: ListView(
            children: [
              // Theme settings
              _buildSectionHeader('Appearance', themeProvider),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Dark Mode'),
                      subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showThemeDialog(context, themeProvider),
                    ),
                  ],
                ),
              ),

              // Notification settings
              _buildSectionHeader('Notifications', themeProvider),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive notifications for new messages'),
                      trailing: Switch(
                        value: true, // TODO: Get from storage
                        onChanged: (value) {
                          // TODO: Update notification settings
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.volume_up),
                      title: const Text('Sound'),
                      subtitle: const Text('Play sound for notifications'),
                      trailing: Switch(
                        value: true, // TODO: Get from storage
                        onChanged: (value) {
                          // TODO: Update sound settings
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.vibration),
                      title: const Text('Vibration'),
                      subtitle: const Text('Vibrate for notifications'),
                      trailing: Switch(
                        value: true, // TODO: Get from storage
                        onChanged: (value) {
                          // TODO: Update vibration settings
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Privacy settings
              _buildSectionHeader('Privacy & Security', themeProvider),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your account password'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to change password
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.visibility),
                      title: const Text('Online Status'),
                      subtitle: const Text('Show when you\'re online'),
                      trailing: Switch(
                        value: true, // TODO: Get from user settings
                        onChanged: (value) {
                          // TODO: Update online status visibility
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Last Seen'),
                      subtitle: const Text('Show your last seen time'),
                      trailing: Switch(
                        value: true, // TODO: Get from user settings
                        onChanged: (value) {
                          // TODO: Update last seen visibility
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Storage settings
              _buildSectionHeader('Storage & Data', themeProvider),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Storage Usage'),
                      subtitle: const Text('Manage app storage and cache'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to storage management
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Auto-download Media'),
                      subtitle: const Text('Automatically download images and files'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to auto-download settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep),
                      title: const Text('Clear Cache'),
                      subtitle: const Text('Free up space by clearing cached data'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showClearCacheDialog(context),
                    ),
                  ],
                ),
              ),

              // Help & Support
              _buildSectionHeader('Help & Support', themeProvider),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Help Center'),
                      subtitle: const Text('Get help and support'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to help center
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.feedback),
                      title: const Text('Send Feedback'),
                      subtitle: const Text('Help us improve the app'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to feedback
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('About'),
                      subtitle: Text('Version ${AppConstants.appVersion}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),

              // Account actions
              _buildSectionHeader('Account', themeProvider),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppConstants.errorRed),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: AppConstants.errorRed),
                      ),
                      subtitle: const Text('Sign out of your account'),
                      onTap: () => _showLogoutDialog(context, authProvider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: AppConstants.errorRed),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: AppConstants.errorRed),
                      ),
                      subtitle: const Text('Permanently delete your account'),
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.largePadding),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.largePadding,
        AppConstants.largePadding,
        AppConstants.largePadding,
        AppConstants.smallPadding,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AppConstants.primaryBlue,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data including images and temporary files. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppConstants.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppConstants.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement account deletion
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppConstants.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese: '© 2024 ${AppConstants.organizationName}',
      children: [
        const SizedBox(height: 16),
        const Text(
          'A modern real-time chat application built with Flutter.',
        ),
      ],
    );
  }
}