import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/features/profile/presentation/screens/edit_employer_profile_screen.dart';
import 'package:jobspot_app/features/profile/presentation/screens/edit_seeker_profile_screen.dart';
import 'package:jobspot_app/data/services/profile_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button
        actions: [
          // Optional: Add sign out button if needed, but user didn't explicitly ask for it here.
          // Keeping it clean as requested.
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Choose Your Role',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Are you looking for a job or looking to hire someone?',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Role Options
              _buildRoleCard(
                role: 'seeker',
                title: 'Job Seeker',
                description:
                    'I want to find my dream job and advance my career.',
                icon: Icons.person_search_outlined,
              ),
              const SizedBox(height: 20),
              _buildRoleCard(
                role: 'employer',
                title: 'Employer',
                description: 'I want to find the best talent for my company.',
                icon: Icons.business_outlined,
              ),

              const Spacer(),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _selectedRole == null
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            final user = SupabaseService.getCurrentUser();
                            if (user != null) {
                              // 1. Create Initial Profile
                              final profileService = ProfileService();
                              await profileService.createInitialProfile(
                                user.id,
                                _selectedRole!,
                              );

                              if (!mounted) return;

                              // 2. Navigate to Edit Profile with Slide Transition
                              Widget nextScreen;
                              if (_selectedRole == 'seeker') {
                                nextScreen = const EditSeekerProfileScreen(
                                  profile: null, // New profile
                                );
                              } else {
                                nextScreen = const EditEmployerProfileScreen(
                                  profile: null, // New profile
                                );
                              }

                              // ignore: use_build_context_synchronously
                              Navigator.push(
                                context,
                                _createSlideRoute(nextScreen),
                              );
                            } else {
                              // Fallback for non-auth flow (shouldn't happen in this context usually)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SignupScreen(role: _selectedRole!),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).iconTheme.color,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.purple, size: 24),
          ],
        ),
      ),
    );
  }

  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
