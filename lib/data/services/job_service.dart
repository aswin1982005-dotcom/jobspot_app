import 'package:supabase_flutter/supabase_flutter.dart';

class JobService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<PostgrestList> fetchJobs({
    String? location,
    bool? sameDayPay,
    bool? walkIn,
    String? payType,
    String? workMode,
    List<String>? workingDays,
  }) async {
    var query = _client.from('job_posts').select().eq('is_active', true);

    if (location != null && location.isNotEmpty) {
      query = query.ilike('location', '%$location%');
    }

    if (sameDayPay != null) {
      query = query.eq('same_day_pay', sameDayPay);
    }

    if (walkIn != null) {
      query = query.eq('is_walk_in', walkIn);
    }

    if (payType != null) {
      query = query.eq('pay_type', payType);
    }

    if (workMode != null) {
      query = query.eq('work_mode', workMode);
    }

    if (workingDays != null && workingDays.isNotEmpty) {
      query = query.contains('working_days', workingDays);
    }

    final response = await query.order('created_at', ascending: false);
    return PostgrestList.from(response);
  }

  Future<PostgrestList> fetchEmployerJobs() async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('job_posts')
        .select()
        .eq('employer_id', userId)
        .order('created_at', ascending: false);

    return PostgrestList.from(response);
  }

  Future<void> createJobPost(PostgrestMap jobData) async {
    await _client.from('job_posts').insert(jobData);
  }

  /// Updates an existing job post with the provided [jobId] and [jobData].
  Future<void> updateJobPost(String jobId, PostgrestMap jobData) async {
    await _client.from('job_posts').update(jobData).eq('id', jobId);
  }

  // --- Saved Jobs Methods ---

  Future<List<Map<String, dynamic>>> fetchSavedJobs() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('saved_jobs')
        .select('*, job_posts(*)')
        .eq('seeker_id', userId)
        .order('saved_at', ascending: false);
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> toggleSaveJob(String jobId, bool isCurrentlySaved) async {
    final userId = _client.auth.currentUser!.id;
    if (isCurrentlySaved) {
      await _client
          .from('saved_jobs')
          .delete()
          .eq('seeker_id', userId)
          .eq('job_id', jobId);
    } else {
      await _client.from('saved_jobs').insert({
        'seeker_id': userId,
        'job_id': jobId,
      });
    }
  }

  Future<bool> isJobSaved(String jobId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final response = await _client
        .from('saved_jobs')
        .select()
        .eq('seeker_id', userId)
        .eq('job_id', jobId)
        .maybeSingle();
    return response != null;
  }

  Future<void> updateJobStatus(String jobId, bool newStatus) async {
    await _client
        .from('job_posts')
        .update({'is_active': newStatus})
        .eq('id', jobId);
  }
}
