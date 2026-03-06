import 'package:flutter/material.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/core/utils/global_refresh_manager.dart';
import 'package:jobspot_app/data/services/profile_service.dart';
import 'package:jobspot_app/features/profile/presentation/screens/edit_seeker_profile_screen.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/profile_widgets.dart';

import 'package:jobspot_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:jobspot_app/features/profile/presentation/screens/help_support_screen.dart';
import 'package:jobspot_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:jobspot_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:jobspot_app/features/reviews/presentation/seeker_reviews_screen.dart';

class SeekerProfileView extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final bool isAdminView;
  final String? userId;

  const SeekerProfileView({
    super.key,
    this.profileData,
    this.isAdminView = false,
    this.userId,
  });

  @override
  State<SeekerProfileView> createState() => _SeekerProfileViewState();
}

class _SeekerProfileViewState extends State<SeekerProfileView> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.profileData != null) {
      if (mounted) {
        setState(() {
          _profile = widget.profileData;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final userId = widget.userId ?? SupabaseService.getCurrentUser()?.id;

      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // If it's the current user and not admin view, we can use the provider
      // But for simplicity and consistency with admin view, let's fetch directly or check provider
      if (widget.userId == null && !widget.isAdminView) {
        // Fallback to provider if desired, but here we fetch directly to support the 'userId' logic cleanly
      }

      final data = await ProfileService().fetchSeekerProfile(userId);
      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
        });

        if (data == null && widget.isAdminView) {
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

    // If we still don't have profile but are main user, maybe Provider has it?
    // This is a fail-safe.
    if (_profile == null && widget.userId == null && !widget.isAdminView) {
      return Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.profileData != null) {
            return _buildContent(context, provider.profileData);
          }
          // Trigger fetch if needed
          final user = SupabaseService.getCurrentUser();
          if (user != null && provider.profileData == null) {
            Future.microtask(() => provider.fetchProfile(user.id));
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(context, null);
        },
      );
    }

    return _buildContent(context, _profile);
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic>? profile) {
    if (profile == null) {
      return RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 80,
                      color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Complete Your Profile',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Set up your profile to start applying for jobs and get personalized recommendations.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToEditProfile(context, null),
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Still allow logout even without profile
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
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            ProfileHeader(
              title: profile['full_name'] ?? 'User',
              subtitle: widget.isAdminView
                  ? 'Seeker Account'
                  : (SupabaseService.getCurrentUser()?.email ?? ''),
              onEdit: widget.isAdminView
                  ? null
                  : () => _navigateToEditProfile(context, profile),
              actions: [
                if (!widget.isAdminView) ...[
                  IconButton(
                    onPressed: () => GlobalRefreshManager.refreshAll(context),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Consumer<NotificationProvider>(
                        builder: (context, notifProvider, child) {
                          return Badge(
                            label: notifProvider.unreadCount > 0
                                ? Text('${notifProvider.unreadCount}')
                                : null,
                            isLabelVisible: notifProvider.unreadCount > 0,
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
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
                          value: profile['education_level'] ?? 'Not provided',
                        ),
                        ProfileInfoTile(
                          icon: Icons.bolt_outlined,
                          label: 'Skills',
                          value:
                              (profile['skills'] as List?)?.join(', ') ??
                              'Not provided',
                        ),
                        ProfileInfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'City',
                          value: profile['city'] ?? 'Not provided',
                        ),
                        ProfileInfoTile(
                          icon: Icons.work_outline,
                          label: 'Job Preference',
                          value:
                              profile['preferred_job_type'] ?? 'Not provided',
                        ),
                        if (profile['assets'] != null &&
                            (profile['assets'] as List).isNotEmpty)
                          ProfileInfoTile(
                            icon: Icons.inventory_2_outlined,
                            label: 'Assets',
                            value: (profile['assets'] as List).join(', '),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!widget.isAdminView) ...[
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

                    // See Reviews
                    ProfileMenuTile(
                      icon: Icons.star_outline,
                      title: 'My Reviews',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeekerReviewsScreen(
                              seekerId: SupabaseService.getCurrentUser()!.id,
                              seekerName: profile['full_name'] ?? 'Me',
                              canWriteReview: false,
                            ),
                          ),
                        );
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
                  ] else ...[
                    // Admin View Extras?
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
      // Refresh logic if needed
      _loadProfile();
      // If we are using provider fallback, update it too
      if (widget.userId == null) {
        context.read<ProfileProvider>().refreshProfile();
      }
    }
  }
}
