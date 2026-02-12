import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/admin_service.dart';

class SupportProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _userReports = [];
  List<Map<String, dynamic>> _jobReports = [];
  String? _statusFilter;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get userReports => _userReports;
  List<Map<String, dynamic>> get jobReports => _jobReports;
  String? get statusFilter => _statusFilter;

  // Combined reports list for display
  List<Map<String, dynamic>> get allReports {
    final combined = <Map<String, dynamic>>[];

    // Add user reports with type indicator
    for (final report in _userReports) {
      combined.add({...report, 'report_category': 'user_report'});
    }

    // Add job reports with type indicator
    for (final report in _jobReports) {
      combined.add({...report, 'report_category': 'job_report'});
    }

    // Sort by created_at descending
    combined.sort((a, b) {
      final aDate = DateTime.parse(a['created_at'] ?? '');
      final bDate = DateTime.parse(b['created_at'] ?? '');
      return bDate.compareTo(aDate);
    });

    return combined;
  }

  /// Load all reports with current filter
  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _adminService.fetchUserReports(statusFilter: _statusFilter),
        _adminService.fetchJobReports(statusFilter: _statusFilter),
      ]);

      _userReports = results[0];
      _jobReports = results[1];
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadReports();
  }

  /// Clear filter
  void clearFilter() {
    _statusFilter = null;
    loadReports();
  }

  /// Update report status
  Future<void> updateReportStatus({
    required String reportId,
    required bool isUserReport,
    required String status,
    String? adminNotes,
  }) async {
    try {
      await _adminService.updateReportStatus(
        reportId: reportId,
        isUserReport: isUserReport,
        status: status,
        adminNotes: adminNotes,
      );
      await loadReports(); // Refresh list
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating report status: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh reports list
  Future<void> refresh() => loadReports();
}
