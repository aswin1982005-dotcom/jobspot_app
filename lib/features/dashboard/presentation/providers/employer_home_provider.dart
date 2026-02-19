import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerHomeProvider extends ChangeNotifier {
  final JobService _jobService = JobService();
  final ApplicationService _applicationService = ApplicationService();

  PostgrestList _jobs = [];
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = false;
  String? _error;

  PostgrestList get jobs => _jobs;
  List<Map<String, dynamic>> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeJobsCount => _jobs.where((j) => j['is_active'] == true).length;
  int get closedJobsCount => _jobs.where((j) => j['is_active'] == false).length;
  int get totalApplicants => _applications.length;

  List<dynamic> get activePostings =>
      _jobs.where((j) => j['is_active'] == true).take(3).toList();
  List<Map<String, dynamic>> get recentApplicants =>
      _applications.take(3).toList();

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _jobService.fetchEmployerJobs(),
        _applicationService.fetchJobApplications(),
      ]);

      _jobs = results[0];
      _applications = List<Map<String, dynamic>>.from(results[1]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadData();

  void updateJob(Map<String, dynamic> updatedJob) {
    final index = _jobs.indexWhere((j) => j['id'] == updatedJob['id']);
    if (index != -1) {
      _jobs[index] = updatedJob;
      notifyListeners();
    }
  }

  void addJob(Map<String, dynamic> newJob) {
    _jobs.insert(0, newJob);
    notifyListeners();
  }
}
