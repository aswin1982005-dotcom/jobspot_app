import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/edit_business_profile_dialog.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:provider/provider.dart';

class EmployerProfileView extends StatefulWidget {
  const EmployerProfileView({super.key});

  @override
  State<StatefulWidget> createState() => _EmployerProfileViewState();
}

class _EmployerProfileViewState extends State<EmployerProfileView> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        _profile = await ProfileService.fetchEmployerProfile(user.id);
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error1 $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Company Header
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.primary,
            child: const Icon(Icons.business, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            _profile?['company_name'] ?? 'Loading...',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            '${_profile?['industry'] ?? ''} • ${_profile?['city'] ?? ''}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Business Info Section
          const ProfileSectionHeader(title: 'Business Information'),
          const SizedBox(height: 12),
          const ProfileInfoTile(
            icon: Icons.language,
            label: 'Website',
            value: 'www.google.com',
          ),
          ProfileInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _profile?['official_email'] ?? '',
          ),
          ProfileInfoTile(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _profile?['contact_mobile'] ?? '',
          ),
          ProfileInfoTile(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: _profile?['city'] ?? '',
          ),

          const SizedBox(height: 32),

          // Settings Section
          const ProfileSectionHeader(title: 'Settings'),
          const SizedBox(height: 12),
          ProfileMenuTile(
            icon: Icons.settings_display,
            title: 'Dark Mode',
            onTap: () {},
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                  child: Icon(
                    themeNotifier.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    key: ValueKey<bool>(themeNotifier.isDarkMode),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: themeNotifier.isDarkMode,
                  activeThumbColor: colorScheme.primary,
                  onChanged: (value) {
                    themeNotifier.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
          ),

          ProfileMenuTile(
            icon: Icons.edit_outlined,
            title: 'Edit Business Profile',
            onTap: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) =>
                    EditBusinessProfileDialog(profile: _profile),
              );
              if (result == true) {
                fetchUserProfile();
              }
            },
          ),
          ProfileMenuTile(
            icon: Icons.notifications_none,
            title: 'Notification Settings',
            onTap: () {},
          ),
          ProfileMenuTile(
            icon: Icons.security_outlined,
            title: 'Security & Password',
            onTap: () {},
          ),
          ProfileMenuTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await SupabaseService.signOut();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              },
              icon: Icon(Icons.logout, color: colorScheme.error),
              label: Text(
                'Log Out',
                style: TextStyle(color: colorScheme.error),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: colorScheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
