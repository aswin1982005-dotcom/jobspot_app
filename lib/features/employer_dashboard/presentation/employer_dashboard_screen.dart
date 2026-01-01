import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/tabs/employer_home_tab.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/tabs/job_posting_tab.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/tabs/applicants_tab.dart';
import 'package:jobspot_app/features/profile/presentation/profile_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  int _selectedIndex = 0;
  
  final JobService _jobService = JobService();
  final ApplicationService _applicationService = ApplicationService();

  PostgrestList _jobs = [];
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _jobService.fetchEmployerJobs(),
        _applicationService.fetchJobApplications(),
      ]);

      if (mounted) {
        setState(() {
          _jobs = results[0] as PostgrestList;
          _applications = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Job Postings',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'Applicants',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _jobs.isEmpty && _applications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return IndexedStack(
      index: _selectedIndex,
      children: [
        EmployerHomeTab(
          jobs: _jobs,
          applications: _applications,
          onRefresh: _handleRefresh,
        ),
        JobPostingTab(
          jobs: _jobs,
          onRefresh: _handleRefresh,
        ),
        ApplicantsTab(
          applications: _applications,
          onRefresh: _handleRefresh,
        ),
        const ProfileTab(role: 'employer'),
      ],
    );
  }
}
