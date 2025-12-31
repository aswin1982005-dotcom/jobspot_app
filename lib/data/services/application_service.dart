import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    await _client
        .from('job_applications')
        .update({'status': status})
        .eq('id', applicationId);
  }

  Future<List<Map<String, dynamic>>> fetchMyApplications() async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('job_applications')
        .select('*, job_posts(*)')
        .eq('applicant_id', userId)
        .order('applied_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> fastApply({
    required String jobPostId,
    required String message,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('job_applications').insert({
      'job_post_id': jobPostId,
      'applicant_id': userId,
      'application_type': 'fast_apply',
      'message': message,
    });
  }
}
