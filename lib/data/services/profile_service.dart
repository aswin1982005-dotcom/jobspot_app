import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          .upsert(updateData)
          .eq('id', userId);
    }
  }

  static Future<void> updateSeekerProfile(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    // Separate profile_completed key if present to update user_profiles
    if (updateData.containsKey('profile_completed')) {
      await _supabase.from('user_profiles').upsert({
        'user_id': userId,
        'profile_completed': updateData['profile_completed'],
      });
      updateData.remove('profile_completed');
    }

    if (updateData.isNotEmpty) {
      await _supabase
          .from('job_seeker_profiles')
          .upsert(updateData)
          .eq('id', userId);
    }
  }

  static Future<String?> uploadResume(
    String userId,
    File file,
    String extension,
  ) async {
    final fileName =
        '$userId/resume_${DateTime.now().millisecondsSinceEpoch}.$extension';
    try {
      await _supabase.storage
          .from('resumes')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      return _supabase.storage.from('resumes').getPublicUrl(fileName);
    } catch (e) {
      // If bucket doesn't exist or permission denied
      print('Error uploading resume: $e');
      rethrow;
    }
  }
}
