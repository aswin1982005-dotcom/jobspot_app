import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/admin_service.dart';

class JobManagementProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _jobs = [];
  bool? _activeFilter;
  bool? _reportedFilter;
  bool? _adminDisabledFilter;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get jobs => _jobs;
  bool? get activeFilter => _activeFilter;
  bool? get reportedFilter => _reportedFilter;
  bool? get adminDisabledFilter => _adminDisabledFilter;

  /// Load jobs with current filters
  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _adminService.fetchAllJobs(
        activeOnly: _activeFilter,
        reportedOnly: _reportedFilter,
        adminDisabledOnly: _adminDisabledFilter,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading jobs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set active filter
  void setActiveFilter(bool? active) {
    _activeFilter = active;
    loadJobs();
  }

  /// Set reported filter
  void setReportedFilter(bool? reported) {
    _reportedFilter = reported;
    loadJobs();
  }

  /// Set admin disabled filter
  void setAdminDisabledFilter(bool? disabled) {
    _adminDisabledFilter = disabled;
    loadJobs();
  }

  /// Clear all filters
  void clearFilters() {
    _activeFilter = null;
    _reportedFilter = null;
    _adminDisabledFilter = null;
    loadJobs();
  }

  /// Disable a job
  Future<void> disableJob(String jobId, String reason) async {
    try {
      await _adminService.disableJob(jobId, reason);
      await loadJobs(); // Refresh list
    } catch (e) {
      _error = e.toString();
      debugPrint('Error disabling job: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Enable a job
  Future<void> enableJob(String jobId) async {
    try {
      await _adminService.enableJob(jobId);
      await loadJobs(); // Refresh list
    } catch (e) {
      _error = e.toString();
      debugPrint('Error enabling job: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Add notes to a job
  Future<void> addJobNotes(String jobId, String notes) async {
    try {
      await _adminService.addJobNotes(jobId, notes);
      await loadJobs(); // Refresh list
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding job notes: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh jobs list
  Future<void> refresh() => loadJobs();

  /// Fetch reports for a specific job
  Future<List<Map<String, dynamic>>> fetchJobReports(String jobId) =>
      _adminService.fetchReportsForJob(jobId);
}
