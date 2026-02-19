import 'package:flutter/material.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/core/utils/global_refresh_manager.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/features/profile/presentation/screens/edit_employer_profile_screen.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:jobspot_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:jobspot_app/features/profile/presentation/screens/help_support_screen.dart';
import 'package:jobspot_app/features/reviews/presentation/company_reviews_screen.dart';

class EmployerProfileView extends StatefulWidget {
  const EmployerProfileView({super.key});

  @override
  State<StatefulWidget> createState() => _EmployerProfileViewState();
}

class _EmployerProfileViewState extends State<EmployerProfileView> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        final profileService = ProfileService();
        _profile = await profileService.fetchEmployerProfile(user.id);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
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
          // Header
          ProfileHeader(
            title: _profile?['company_name'] ?? 'Loading...',
            subtitle:
                '${_profile?['industry'] ?? 'Not Provided'} • ${_profile?['city'] ?? 'Not Provided'}',
            fallbackIcon: Icons.business,
            onEdit: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditEmployerProfileScreen(profile: _profile),
                ),
              );
              if (result == true) {
                fetchUserProfile();
              }
            },
            actions: [
              IconButton(
                onPressed: () => GlobalRefreshManager.refreshAll(context),
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
              ),
            ],
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Business Info Section
                const ProfileSectionHeader(title: 'Business Information'),
                const SizedBox(height: 12),
                ProfileInfoTile(
                  icon: Icons.language,
                  label: 'Website',
                  value: _profile?['website'] ?? 'Not provided',
                ),
                ProfileInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Official Email',
                  value: _profile?['official_email'] ?? 'Not provided',
                ),
                ProfileInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Contact Number',
                  value: _profile?['contact_mobile'] ?? 'Not provided',
                ),
                ProfileInfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'City',
                  value: _profile?['city'] ?? 'Not provided',
                ),

                const SizedBox(height: 24),

                // Settings Section
                const ProfileSectionHeader(title: 'Settings'),
                const SizedBox(height: 12),
                const ThemeModeTile(),
                ProfileMenuTile(
                  icon: Icons.notifications_none,
                  title: 'Notification Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                ProfileMenuTile(
                  icon: Icons.security_outlined,
                  title: 'Security & Password',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                ProfileMenuTile(
                  icon: Icons.star_outline,
                  title: 'My Company Reviews',
                  onTap: () {
                    if (_profile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyReviewsScreen(
                            companyId: SupabaseService.getCurrentUser()!.id,
                            companyName:
                                _profile!['company_name'] ?? 'My Company',
                          ),
                        ),
                      );
                    }
                  },
                ),
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

                const SizedBox(height: 32),

                // Logout Button
                LogoutButton(
                  onLogout: () async {
                    try {
                      await SupabaseService.signOut();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
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
