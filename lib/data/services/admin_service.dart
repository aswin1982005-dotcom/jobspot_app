import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // USER MANAGEMENT
  // ============================================================================

  /// Fetch all users with optional filtering
  Future<List<Map<String, dynamic>>> fetchAllUsers({
    String? roleFilter,
    bool? disabledOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase.from('user_profiles').select('''
          user_id,
          role,
          profile_completed,
          is_disabled,
          disabled_at,
          disable_reason,
          created_at,
          seekers:seeker_profiles(full_name, bio, avatar_url, phone_number, city, state),
          employers:employer_profiles(company_name, company_bio, logo_url, contact_email, city, state)
        ''');

    if (roleFilter != null) {
      query = query.eq('role', roleFilter);
    }

    if (disabledOnly != null) {
      query = query.eq('is_disabled', disabledOnly);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Disable a user account
  Future<void> disableUser(String userId, String reason) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) throw Exception('Not authenticated');

    // Update user profile
    await _supabase
        .from('user_profiles')
        .update({
          'is_disabled': true,
          'disabled_at': DateTime.now().toIso8601String(),
          'disabled_by': adminId,
          'disable_reason': reason,
        })
        .eq('user_id', userId);

    // Log admin action
    await _logAdminAction(
      actionType: 'disable_user',
      targetType: 'user',
      targetId: userId,
      reason: reason,
    );
  }

  /// Enable a previously disabled user account
  Future<void> enableUser(String userId) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) throw Exception('Not authenticated');

    // Update user profile
    await _supabase
        .from('user_profiles')
        .update({
          'is_disabled': false,
          'disabled_at': null,
          'disabled_by': null,
          'disable_reason': null,
        })
        .eq('user_id', userId);

    // Log admin action
    await _logAdminAction(
      actionType: 'enable_user',
      targetType: 'user',
      targetId: userId,
    );
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    final response = await _supabase.rpc('get_user_statistics');
    return Map<String, dynamic>.from(response);
  }

  // ============================================================================
  // JOB MANAGEMENT
  // ============================================================================

  /// Fetch all jobs with optional filtering
  Future<List<Map<String, dynamic>>> fetchAllJobs({
    bool? activeOnly,
    bool? reportedOnly,
    bool? adminDisabledOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase.from('job_posts').select('''
          *,
          employer:employer_profiles!job_posts_posted_by_fkey(
            company_name,
            logo_url,
            city,
            state
          )
        ''');

    if (activeOnly != null) {
      query = query.eq('is_active', activeOnly);
    }

    if (reportedOnly == true) {
      query = query.eq('is_reported', true);
    }

    if (adminDisabledOnly == true) {
      query = query.eq('admin_disabled', true);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Admin disable a job
  Future<void> disableJob(String jobId, String reason) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) throw Exception('Not authenticated');

    await _supabase
        .from('job_posts')
        .update({
          'admin_disabled': true,
          'admin_notes': reason,
          'is_active': false, // Also mark as inactive
        })
        .eq('id', jobId);

    // Log admin action
    await _logAdminAction(
      actionType: 'disable_job',
      targetType: 'job',
      targetId: jobId,
      reason: reason,
    );
  }

  /// Enable a previously disabled job
  Future<void> enableJob(String jobId) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) throw Exception('Not authenticated');

    await _supabase
        .from('job_posts')
        .update({
          'admin_disabled': false,
          'admin_notes': null,
          'is_active': true, // Re-activate
        })
        .eq('id', jobId);

    // Log admin action
    await _logAdminAction(
      actionType: 'enable_job',
      targetType: 'job',
      targetId: jobId,
    );
  }

  /// Add admin notes to a job
  Future<void> addJobNotes(String jobId, String notes) async {
    await _supabase
        .from('job_posts')
        .update({'admin_notes': notes})
        .eq('id', jobId);

    // Log admin action
    await _logAdminAction(
      actionType: 'add_job_note',
      targetType: 'job',
      targetId: jobId,
      metadata: {'notes': notes},
    );
  }

  /// Get job statistics
  Future<Map<String, dynamic>> getJobStatistics() async {
    final response = await _supabase.rpc('get_job_statistics');
    return Map<String, dynamic>.from(response);
  }

  // ============================================================================
  // REPORT MANAGEMENT
  // ============================================================================

  /// Fetch user reports
  Future<List<Map<String, dynamic>>> fetchUserReports({
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase.from('user_reports').select('''
          *,
          reporter:reporter_id(id, email),
          reported_user:user_profiles!user_reports_reported_user_id_fkey(
            user_id,
            role,
            seekers:seeker_profiles(full_name, avatar_url),
            employers:employer_profiles(company_name, logo_url)
          ),
          resolver:user_profiles!user_reports_resolved_by_fkey(
            user_id,
            seekers:seeker_profiles(full_name),
            employers:employer_profiles(company_name)
          )
        ''');

    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch job reports
  Future<List<Map<String, dynamic>>> fetchJobReports({
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase.from('job_reports').select('''
          *,
          reporter:reporter_id(id, email),
          job:job_posts(
            id,
            title,
            company,
            city,
            state,
            is_active,
            admin_disabled
          ),
          resolver:user_profiles!job_reports_resolved_by_fkey(
            user_id,
            seekers:seeker_profiles(full_name),
            employers:employer_profiles(company_name)
          )
        ''');

    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update report status
  Future<void> updateReportStatus({
    required String reportId,
    required bool isUserReport,
    required String status,
    String? adminNotes,
  }) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) throw Exception('Not authenticated');

    final table = isUserReport ? 'user_reports' : 'job_reports';

    final updates = {
      'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (status == 'resolved' || status == 'dismissed') ...{
        'resolved_by': adminId,
        'resolved_at': DateTime.now().toIso8601String(),
      },
    };

    await _supabase.from(table).update(updates).eq('id', reportId);

    // Log admin action
    await _logAdminAction(
      actionType: 'resolve_report',
      targetType: 'report',
      targetId: reportId,
      metadata: {
        'report_type': isUserReport ? 'user_report' : 'job_report',
        'status': status,
      },
    );
  }

  /// Create a user report
  Future<void> createUserReport({
    required String reportedUserId,
    required String reportType,
    required String description,
  }) async {
    final reporterId = _supabase.auth.currentUser?.id;
    if (reporterId == null) throw Exception('Not authenticated');

    await _supabase.from('user_reports').insert({
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'report_type': reportType,
      'description': description,
    });
  }

  /// Create a job report
  Future<void> createJobReport({
    required String jobId,
    required String reportType,
    required String description,
  }) async {
    final reporterId = _supabase.auth.currentUser?.id;
    if (reporterId == null) throw Exception('Not authenticated');

    await _supabase.from('job_reports').insert({
      'reporter_id': reporterId,
      'job_id': jobId,
      'report_type': reportType,
      'description': description,
    });

    // Mark job as reported
    await _supabase
        .from('job_posts')
        .update({
          'is_reported': true,
          'reported_at': DateTime.now().toIso8601String(),
        })
        .eq('id', jobId);
  }

  /// Get report statistics
  Future<Map<String, dynamic>> getReportStatistics() async {
    final response = await _supabase.rpc('get_report_statistics');
    return Map<String, dynamic>.from(response);
  }

  // ============================================================================
  // ADMIN ACTIONS (AUDIT LOG)
  // ============================================================================

  /// Fetch recent admin actions
  Future<List<Map<String, dynamic>>> fetchAdminActions({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('admin_actions')
        .select('''
          *,
          admin:user_profiles!admin_actions_admin_id_fkey(
            user_id,
            seekers:seeker_profiles(full_name),
            employers:employer_profiles(company_name)
          )
        ''')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Log an admin action (internal helper)
  Future<void> _logAdminAction({
    required String actionType,
    required String targetType,
    required String targetId,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) return;

    await _supabase.from('admin_actions').insert({
      'admin_id': adminId,
      'action_type': actionType,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'metadata': metadata ?? {},
    });
  }

  // ============================================================================
  // DASHBOARD OVERVIEW
  // ============================================================================

  /// Fetch dashboard overview data
  Future<Map<String, dynamic>> fetchDashboardOverview() async {
    final results = await Future.wait([
      getUserStatistics(),
      getJobStatistics(),
      getReportStatistics(),
    ]);

    return {
      'user_stats': results[0],
      'job_stats': results[1],
      'report_stats': results[2],
    };
  }

  /// Fetch recent activity (users and jobs)
  Future<Map<String, dynamic>> fetchRecentActivity() async {
    final recentUsers = await _supabase
        .from('user_profiles')
        .select('''
          user_id,
          role,
          created_at,
          seekers:seeker_profiles(full_name, avatar_url),
          employers:employer_profiles(company_name, logo_url)
        ''')
        .order('created_at', ascending: false)
        .limit(5);

    final recentJobs = await _supabase
        .from('job_posts')
        .select('''
          id,
          title,
          company,
          city,
          state,
          created_at,
          is_active,
          admin_disabled
        ''')
        .order('created_at', ascending: false)
        .limit(5);

    return {
      'recent_users': List<Map<String, dynamic>>.from(recentUsers),
      'recent_jobs': List<Map<String, dynamic>>.from(recentJobs),
    };
  }
}
