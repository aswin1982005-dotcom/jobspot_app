import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/data/services/job_service.dart';

class SeekerHomeProvider extends ChangeNotifier {
  final JobService _jobService = JobService();
  final ApplicationService _applicationService = ApplicationService();

  List<Map<String, dynamic>> _savedJobs = [];
  List<Map<String, dynamic>> _recommendedJobs = [];
  List<Map<String, dynamic>> _myApplications = [];
  Set<String> _appliedJobIds = {};

  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get savedJobs => _savedJobs;

  List<Map<String, dynamic>> get recommendedJobs => _recommendedJobs;

  List<Map<String, dynamic>> get myApplications => _myApplications;

  Set<String> get appliedJobIds => _appliedJobIds;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get appliedCount => _myApplications.length;

  int get interviewCount =>
      _myApplications.where((a) => a['status'] == 'interview').length;

  int get selectedCount =>
      _myApplications.where((a) => a['status'] == 'hired').length;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _jobService.fetchSavedJobs(),
        _jobService.fetchJobs(), // Recommended
        _applicationService.fetchMyApplications(),
      ]);

      _savedJobs = List<Map<String, dynamic>>.from(results[0]);
      _recommendedJobs = List<Map<String, dynamic>>.from(results[1]);
      _myApplications = List<Map<String, dynamic>>.from(results[2]);

      _appliedJobIds = _myApplications
          .map((a) => a['job_post_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isJobApplied(String jobId) => _appliedJobIds.contains(jobId);

  Future<void> refresh() => loadData();
}
