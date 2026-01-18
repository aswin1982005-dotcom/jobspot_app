import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/features/profile/presentation/screens/edit_seeker_profile_screen.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:jobspot_app/features/applications/presentation/my_applications_screen.dart';
import 'package:jobspot_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:jobspot_app/features/profile/presentation/screens/help_support_screen.dart';

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileHeader(
            title: _profile?['full_name'] ?? 'User',
            subtitle: SupabaseService.getCurrentUser()?.email ?? '',
            onEdit: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditSeekerProfileScreen(profile: _profile),
                ),
              );
              if (result == true) {
                _fetchProfile();
              }
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const ProfileSectionHeader(title: 'Personal Information'),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ProfileInfoTile(
                        icon: Icons.school_outlined,
                        label: 'Education',
                        value: _profile?['education_level'] ?? 'Not provided',
                      ),
                      ProfileInfoTile(
                        icon: Icons.bolt_outlined,
                        label: 'Skills',
                        value:
                            (_profile?['skills'] as List?)?.join(', ') ??
                            'Not provided',
                      ),
                      ProfileInfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'City',
                        value: _profile?['city'] ?? 'Not provided',
                      ),
                      ProfileInfoTile(
                        icon: Icons.work_outline,
                        label: 'Job Preference',
                        value:
                            _profile?['preferred_job_type'] ?? 'Not provided',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const ProfileSectionHeader(title: 'Settings'),
                const SizedBox(height: 12),
                const ThemeModeTile(),

                // Account Settings
                ProfileMenuTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                // My Applications
                ProfileMenuTile(
                  icon: Icons.history,
                  title: 'My Applications',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyApplicationsScreen(),
                      ),
                    );
                  },
                ),

                // Resume
                ProfileMenuTile(
                  icon: Icons.description_outlined,
                  title: 'Resume',
                  onTap: () {
                    // Todo: Implement Resume Upload
                  },
                ),

                // Notifications (Can link to settings or specific page)
                ProfileMenuTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    // For now link to settings or show snackbar
                  },
                ),

                // Help & Support
                ProfileMenuTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                LogoutButton(
                  onLogout: () async {
                    try {
                      await SupabaseService.signOut();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
