import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/edit_seeker_profile_dialog.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:provider/provider.dart';

class SeekerProfileView extends StatefulWidget {
  const SeekerProfileView({super.key});

  @override
  State<SeekerProfileView> createState() => _SeekerProfileViewState();
}

class _SeekerProfileViewState extends State<SeekerProfileView> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        final profile = await ProfileService.fetchSeekerProfile(user.id);
        if (mounted) {
          setState(() {
            _profile = profile;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Profile Picture
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _profile?['full_name'] ?? 'User',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SupabaseService.getCurrentUser()?.email ?? '',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                // Edit Profile Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => EditSeekerProfileDialog(profile: _profile),
                    );
                    if (result == true) {
                      _fetchProfile();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Profile Details & Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const ProfileSectionHeader(title: 'Personal Information'),
                const SizedBox(height: 12),
                ProfileInfoTile(
                  icon: Icons.school_outlined,
                  label: 'Education',
                  value: _profile?['education_level'] ?? 'Not provided',
                ),
                ProfileInfoTile(
                  icon: Icons.bolt_outlined,
                  label: 'Skills',
                  value: (_profile?['skills'] as List?)?.join(', ') ?? 'Not provided',
                ),
                ProfileInfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'City',
                  value: _profile?['city'] ?? 'Not provided',
                ),
                ProfileInfoTile(
                  icon: Icons.work_outline,
                  label: 'Job Preference',
                  value: _profile?['preferred_job_type'] ?? 'Not provided',
                ),
                const SizedBox(height: 24),

                const ProfileSectionHeader(title: 'Settings'),
                const SizedBox(height: 12),
                // Theme Toggle
                ProfileMenuTile(
                  icon: themeNotifier.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  title: 'Dark Mode',
                  onTap: () {},
                  trailing: Switch(
                    value: themeNotifier.isDarkMode,
                    activeThumbColor: colorScheme.primary,
                    onChanged: (value) {
                      themeNotifier.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                ),
                ProfileMenuTile(
                  icon: Icons.history,
                  title: 'My Applications',
                  onTap: () {},
                ),
                ProfileMenuTile(
                  icon: Icons.description_outlined,
                  title: 'Resume',
                  onTap: () {},
                ),
                ProfileMenuTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {},
                ),
                ProfileMenuTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await SupabaseService.signOut();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    icon: Icon(Icons.logout, color: colorScheme.error),
                    label: Text(
                      'Logout',
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
                const SizedBox(height: 20),
                Text(
                  'Version 1.0.0',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
