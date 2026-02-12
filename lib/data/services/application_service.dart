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

  Future<List<Map<String, dynamic>>> fetchJobApplications({
    String? jobPostId,
  }) async {
    final userId = _client.auth.currentUser!.id;

    var query = _client.from('job_applications').select('''
          *,
          job_posts!inner(*)
        ''');

    query = query.eq('job_posts.employer_id', userId);

    if (jobPostId != null && jobPostId.isNotEmpty) {
      query = query.eq('job_post_id', jobPostId);
    }

    final response = await query.order('applied_at', ascending: false);
    final applications = List<Map<String, dynamic>>.from(response);

    if (applications.isEmpty) return [];

    // 2. Fetch Applicant Profiles manually
    final applicantIds = applications
        .map((app) => app['applicant_id'] as String)
        .toSet()
        .toList();

    // Fetch profiles from job_seeker_profiles
    final profilesResponse = await _client
        .from('job_seeker_profiles')
        .select(
          'user_id, full_name, profile_photo, city, skills, education_level, availability_status, email, phone',
        )
        .filter('user_id', 'in', applicantIds);

    final profiles = List<Map<String, dynamic>>.from(profilesResponse);
    final profileMap = {for (var p in profiles) p['user_id'] as String: p};

    // 3. Merge Data
    for (var app in applications) {
      final applicantId = app['applicant_id'] as String;
      // Add applicant data to 'applicant' key as expected by UI
      if (profileMap.containsKey(applicantId)) {
        app['applicant'] = profileMap[applicantId];
      } else {
        app['applicant'] = {'full_name': 'Unknown User'};
      }
    }

    return applications;
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
