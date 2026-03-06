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
  final Map<String, dynamic>? profileData;
  final bool isAdminView;
  final String? userId;

  const EmployerProfileView({
    super.key,
    this.profileData,
    this.isAdminView = false,
    this.userId,
  });

  @override
  State<StatefulWidget> createState() => _EmployerProfileViewState();
}

class _EmployerProfileViewState extends State<EmployerProfileView> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.profileData != null) {
      _profile = widget.profileData;
      _isLoading = false;
    } else {
      fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final userId = widget.userId ?? SupabaseService.getCurrentUser()?.id;

      if (userId != null) {
        final profileService = ProfileService();
        _profile = await profileService.fetchEmployerProfile(userId);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (_profile == null && widget.isAdminView) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Profile Incomplete'),
                    content: const Text(
                      'This user has not completed their profile yet.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context); // Go back
                          }
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            });
          }
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

    // Show a "Complete Your Profile" prompt when profile is null for own profile
    if (_profile == null && !widget.isAdminView) {
      return SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 80,
                    color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Complete Your Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set up your company profile to start posting jobs and attracting talent.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditEmployerProfileScreen(profile: null),
                          ),
                        );
                        if (result == true) {
                          fetchUserProfile();
                        }
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        'Set Up Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          ),
        ),
      );
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
            onEdit: widget.isAdminView
                ? null
                : () async {
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
              if (!widget.isAdminView)
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

                if (!widget.isAdminView) ...[
                  // Settings Section
                  const ProfileSectionHeader(title: 'Settings'),
                  const SizedBox(height: 12),
                  const ThemeModeTile(),

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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
