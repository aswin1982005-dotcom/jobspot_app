import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/seeker_home_provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/employer_home_provider.dart';
import 'package:jobspot_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:jobspot_app/core/utils/supabase_service.dart';
import 'package:jobspot_app/features/notifications/presentation/providers/notification_provider.dart';

class GlobalRefreshManager {
  static Future<void> refreshAll(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing all data...'),
        duration: Duration(seconds: 1),
      ),
    );

    // 1. Refresh Seeker/Employer Home Provider
    try {
      try {
        if (!context.mounted) return;
        await context.read<SeekerHomeProvider>().loadData();
      } catch (_) {}

      try {
        if (!context.mounted) return;
        await context.read<EmployerHomeProvider>().loadData();
      } catch (_) {}
    } catch (e) {
      debugPrint('Error refreshing home providers: $e');
    }

    // 2. Refresh Profile
    try {
      final userId = SupabaseService.getCurrentUser()?.id;
      if (userId != null) {
        if (!context.mounted) return;
        await context.read<ProfileProvider>().fetchProfile(userId);
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }

    // 3. Refresh Notifications
    try {
      try {
        if (!context.mounted) return;
        await context.read<NotificationProvider>().refresh();
      } catch (_) {}
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    }
  }
}
