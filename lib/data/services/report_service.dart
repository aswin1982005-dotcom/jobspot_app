import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> reportUser({
    required String reportedUserId,
    required String reportType,
    required String description,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('user_reports').insert({
      'reporter_id': user.id,
      'reported_user_id': reportedUserId,
      'report_type': reportType,
      'description': description,
      'status': 'pending',
    });
  }

  Future<void> reportJob({
    required String jobId,
    required String reportType,
    required String description,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('job_reports').insert({
      'reporter_id': user.id,
      'job_id': jobId,
      'report_type': reportType,
      'description': description,
      'status': 'pending',
    });
  }
}
