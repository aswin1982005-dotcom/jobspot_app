import 'package:flutter/material.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/employer_profile_view.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/seeker_profile_view.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/admin_profile_view.dart';

class ProfileTab extends StatelessWidget {
  final String? role;

  const ProfileTab({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    // If role is provided, use it. Otherwise, try to get it from user metadata.
    final userRole =
        role ??
        SupabaseService.getCurrentUser()?.userMetadata?['role'] as String?;

    return Scaffold(body: SafeArea(child: _buildProfileView(userRole)));
  }

  Widget _buildProfileView(String? role) {
    if (role == 'employer') {
      return const EmployerProfileView();
    }
    if (role == 'admin') {
      return const AdminProfileView();
    }
    // Default to seeker view if role is 'seeker' or unknown
    return const SeekerProfileView();
  }
}
