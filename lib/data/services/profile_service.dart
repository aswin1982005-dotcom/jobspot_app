import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> fetchEmployerProfile(
    String userId,
  ) async {
    return await _supabase
        .from('employer_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  static Future<Map<String, dynamic>?> fetchSeekerProfile(String userId) async {
    return await _supabase
        .from('job_seeker_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  static Future<bool> isProfileComplete(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('profile_completed')
          .eq('user_id', userId)
          .maybeSingle();
      return response?['profile_completed'] == true;
    } catch (e) {
      // If table doesn't exist or error, return false or handle appropriately
      return false;
    }
  }

  static Future<void> updateEmployerProfile(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    // Separate profile_completed key if present to update user_profiles
    if (updateData.containsKey('profile_completed')) {
      await _supabase.from('user_profiles').upsert({
        'user_id': userId,
        'profile_completed': updateData['profile_completed'],
      });
      // Remove it from updateData if employer_profiles doesn't have this column
      // To be safe, we can leave it if we are unsure, but ideally we separate.
      // Assuming employer_profiles might not have it.
      updateData.remove('profile_completed');
    }

    if (updateData.isNotEmpty) {
      await _supabase
          .from('employer_profiles')
          .update(updateData)
          .eq('user_id', userId);
    }
  }

  static Future<void> updateSeekerProfile(
    String userId,
    Map<String, dynamic> updateData, {
    bool complete = false,
  }) async {
    // Separate profile_completed key if present to update user_profiles
    if (complete) {
      await _supabase.from('user_profiles').upsert({
        'user_id': userId,
        'profile_completed': true,
      });
      updateData.remove('profile_completed');
    }

    if (updateData.isNotEmpty) {
      await _supabase
          .from('job_seeker_profiles')
          .upsert(updateData)
          .eq('user_id', userId);
    }
  }

  static Future<void> createInitialProfile(String userId, String role) async {
    try {
      // 1. Create/Update user_profiles entry
      await _supabase.from('user_profiles').upsert({
        'user_id': userId,
        'role': role,
        'profile_completed': false,
      });
    } catch (e) {
      debugPrint('Error creating initial profile: $e');
      rethrow;
    }
  }
}
