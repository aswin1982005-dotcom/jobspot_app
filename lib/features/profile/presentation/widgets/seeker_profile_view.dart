import 'package:flutter/material.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/features/profile/presentation/screens/edit_seeker_profile_screen.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:jobspot_app/features/applications/presentation/my_applications_screen.dart';
import 'package:jobspot_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:jobspot_app/features/profile/presentation/screens/help_support_screen.dart';
import 'package:jobspot_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class SeekerProfileView extends StatelessWidget {
  const SeekerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.profileData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // If data is not loaded yet, try to load it (though manager should have done it)
        if (provider.profileData == null) {
          final user = SupabaseService.getCurrentUser();
          if (user != null) {
            // Avoid build-phase side effect by using microtask
            Future.microtask(() => provider.fetchProfile(user.id));
            return const Center(child: CircularProgressIndicator());
          }
        }

        final profile = provider.profileData;

        return SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(
                title: profile?['full_name'] ?? 'User',
                subtitle: SupabaseService.getCurrentUser()?.email ?? '',
                onEdit: () => _navigateToEditProfile(context, profile),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const ProfileSectionHeader(title: 'Personal Information'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
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
                            value:
                                profile?['education_level'] ?? 'Not provided',
                          ),
                          ProfileInfoTile(
                            icon: Icons.bolt_outlined,
                            label: 'Skills',
                            value:
                                (profile?['skills'] as List?)?.join(', ') ??
                                'Not provided',
                          ),
                          ProfileInfoTile(
                            icon: Icons.location_on_outlined,
                            label: 'City',
                            value: profile?['city'] ?? 'Not provided',
                          ),
                          ProfileInfoTile(
                            icon: Icons.work_outline,
                            label: 'Job Preference',
                            value:
                                profile?['preferred_job_type'] ??
                                'Not provided',
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
                          if (!context.mounted) return;
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
      },
    );
  }

  Future<void> _navigateToEditProfile(
    BuildContext context,
    Map<String, dynamic>? profile,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSeekerProfileScreen(profile: profile),
      ),
    );
    if (result == true && context.mounted) {
      context.read<ProfileProvider>().refreshProfile();
    }
  }
}
