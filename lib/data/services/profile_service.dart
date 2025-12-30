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
}
