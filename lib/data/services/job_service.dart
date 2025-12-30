import 'package:supabase_flutter/supabase_flutter.dart';

class JobService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchJobs({
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
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchEmployerJobs() async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('job_posts')
        .select()
        .eq('employer_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createJobPost(Map<String, dynamic> jobData) async {
    await _client.from('job_posts').insert(jobData);
  }
}
