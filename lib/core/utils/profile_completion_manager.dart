import 'package:flutter/material.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:jobspot_app/features/profile/presentation/screens/edit_employer_profile_screen.dart';
import 'package:jobspot_app/features/profile/presentation/screens/edit_seeker_profile_screen.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/profile_completion_dialog.dart';
import 'package:provider/provider.dart';

class ProfileCompletionManager {
  static Future<void> checkAndPrompt(BuildContext context, String role) async {
    // Wait for the initial build to complete
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!context.mounted) return;

    final provider = context.read<ProfileProvider>();
    final user = SupabaseService.getCurrentUser();

    if (user == null) return;

    // Ensure profile is fetched
    if (provider.profileData == null) {
      await provider.fetchProfile(user.id);
    }

    // Now check completion status from provider
    if (!provider.isProfileCompleted && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ProfileCompletionDialog(
          onFinishSetup: () async {
            if (context.mounted) {
              if (role == 'seeker') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditSeekerProfileScreen(profile: provider.profileData),
                  ),
                );
              } else if (role == 'employer') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEmployerProfileScreen(
                      profile: provider.profileData,
                    ),
                  ),
                );
              }
              // Refresh provider after return
              if (context.mounted) {
                await provider.refreshProfile();
              }
            }
          },
        ),
      );
    }
  }
}
