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
      // Check if SeekerHomeProvider is available in context (it might not be if we are in Employer mode, but usually it's not provided globally if not needed)
      // Actually, dashboard provides it.
      // A safer way is to try-catch or check if we can read it.
      // However, Provider.of(listen:false) throws if not found.
      // We can use context.read<T?>() if the provider was registered as nullable? No.
      // We'll wrap in try-catch.

      try {
        await context.read<SeekerHomeProvider>().loadData();
      } catch (_) {}

      try {
        await context.read<EmployerHomeProvider>().loadData();
      } catch (_) {}
    } catch (e) {
      debugPrint('Error refreshing home providers: $e');
    }

    // 2. Refresh Profile
    try {
      final userId = SupabaseService.getCurrentUser()?.id;
      if (userId != null) {
        await context.read<ProfileProvider>().fetchProfile(userId);
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }

    // 3. Refresh Notifications
    try {
      // Assuming NotificationProvider is available in context
      // We use listen: false which is implied by read
      try {
        await context.read<NotificationProvider>().refresh();
      } catch (_) {
        // NotificationProvider might not be active or refresh might fail
      }
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    }
  }
}
