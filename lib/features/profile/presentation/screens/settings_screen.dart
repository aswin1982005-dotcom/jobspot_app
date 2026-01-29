import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _publicProfile = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = OneSignal.User.pushSubscription.optedIn;
    // Also consider permission status if needed, but opting in/out is the main control
    if (mounted) {
      setState(() {
        _pushNotifications = status ?? false;
      });
    }
  }

  Future<void> _togglePushNotifications(bool enable) async {
    setState(() => _pushNotifications = enable);
    if (enable) {
      OneSignal.User.pushSubscription.optIn();
    } else {
      OneSignal.User.pushSubscription.optOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change Password to be implemented'),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              // Show confirmation dialog
            },
          ),
          const Divider(height: 32),

          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: _pushNotifications,
            onChanged: _togglePushNotifications,
            secondary: const Icon(Icons.notifications_outlined),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            value: _emailNotifications,
            onChanged: (val) => setState(() => _emailNotifications = val),
            secondary: const Icon(Icons.email_outlined),
          ),
          const Divider(height: 32),

          _buildSectionHeader('Privacy'),
          SwitchListTile(
            title: const Text('Public Profile'),
            subtitle: const Text('Allow employers to find you'),
            value: _publicProfile,
            onChanged: (val) => setState(() => _publicProfile = val),
            secondary: const Icon(Icons.public),
          ),
          const Divider(height: 32),

          _buildSectionHeader('About'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            trailing: const Text('1.0.0'),
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
