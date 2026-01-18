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

  static Future<void> updateEmployerProfile(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    await _supabase
        .from('employer_profiles')
        .upsert(updateData)
        .eq('id', userId);
  }

  static Future<void> updateSeekerProfile(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    await _supabase
        .from('job_seeker_profiles')
        .upsert(updateData)
        .eq('id', userId);
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
