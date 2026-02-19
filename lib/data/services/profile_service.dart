import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchEmployerProfile(String userId) async {
    return await _supabase
        .from('employer_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> fetchSeekerProfile(String userId) async {
    return await _supabase
        .from('job_seeker_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<bool> isProfileComplete(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('profile_completed')
          .eq('user_id', userId)
          .maybeSingle();
      return response?['profile_completed'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateEmployerProfile(
    String userId,
    Map<String, dynamic> updateData, {
    bool complete = false,
  }) async {
    await _supabase.from('user_profiles').upsert({
      'user_id': userId,
      'profile_completed': complete,
    });

    if (updateData.isNotEmpty) {
      await _supabase
          .from('employer_profiles')
          .upsert(updateData, onConflict: "user_id");
    }
  }

  Future<void> updateSeekerProfile(
    String userId,
    Map<String, dynamic> updateData, {
    bool complete = false,
  }) async {
    await _supabase.from('user_profiles').upsert({
      'user_id': userId,
      'profile_completed': true,
    });

    if (updateData.isNotEmpty) {
      await _supabase
          .from('job_seeker_profiles')
          .upsert(updateData)
          .eq('user_id', userId);
    }
  }

  Future<void> createInitialProfile(String userId, String role) async {
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
