import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/admin_service.dart';

class AdminHomeProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  String? _error;

  // Statistics
  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _jobStats = {};
  Map<String, dynamic> _reportStats = {};

  // Recent activity
  List<Map<String, dynamic>> _recentUsers = [];
  List<Map<String, dynamic>> _recentJobs = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic> get userStats => _userStats;
  Map<String, dynamic> get jobStats => _jobStats;
  Map<String, dynamic> get reportStats => _reportStats;

  List<Map<String, dynamic>> get recentUsers => _recentUsers;
  List<Map<String, dynamic>> get recentJobs => _recentJobs;

  // Computed values for UI
  int get totalUsers => _userStats['total_users'] ?? 0;
  int get totalSeekers => _userStats['seekers'] ?? 0;
  int get totalEmployers => _userStats['employers'] ?? 0;
  int get disabledUsers => _userStats['disabled'] ?? 0;
  int get recentSignups => _userStats['recent_signups'] ?? 0;

  int get totalJobs => _jobStats['total_jobs'] ?? 0;
  int get activeJobs => _jobStats['active'] ?? 0;
  int get reportedJobs => _jobStats['reported'] ?? 0;
  int get adminDisabledJobs => _jobStats['disabled'] ?? 0;

  int get pendingUserReports => _reportStats['pending'] ?? 0;
  int get pendingJobReports => 0; // Not split in report_stats currently
  int get totalPendingReports => _reportStats['pending'] ?? 0;

  /// Load all dashboard data
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch overview data and recent activity in parallel
      final results = await Future.wait([
        _adminService.fetchDashboardOverview(),
        _adminService.fetchRecentActivity(),
      ]);

      final overview = results[0];
      final activity = results[1];

      _userStats = overview['user_stats'] ?? {};
      _jobStats = overview['job_stats'] ?? {};
      _reportStats = overview['report_stats'] ?? {};

      _recentUsers =
          (activity['recent_users'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      _recentJobs =
          (activity['recent_jobs'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading admin dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() => loadData();
}
