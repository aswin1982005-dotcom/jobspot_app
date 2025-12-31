import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:jobspot_app/features/seeker_dashboard/presentation/widgets/stat_card.dart';
import 'package:jobspot_app/features/jobs/presentation/employer_job_card.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/widgets/applicant_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerHomeTab extends StatefulWidget {
  const EmployerHomeTab({super.key});

  @override
  State<EmployerHomeTab> createState() => _EmployerHomeTabState();
}

class _EmployerHomeTabState extends State<EmployerHomeTab> {
  final JobService _jobService = JobService();
  late Future<PostgrestList> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _refreshJobs();
  }

  void _refreshJobs() {
    setState(() {
      _jobsFuture = _jobService.fetchEmployerJobs();
    });
  }

  Future<void> _toggleJobStatus(Map<String, dynamic> job) async {
    final bool currentStatus = job['is_active'] ?? true;
    try {
      await _jobService.updateJobPost(job['id'], {'is_active': !currentStatus});
      _refreshJobs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10), // Compensation for removed SafeArea
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Google Inc.', style: textTheme.headlineLarge),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_outlined, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stats Cards
          const Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Active Jobs',
                  count: '12',
                  icon: Icons.check_circle_outline,
                  color: Color(0xFF01B307),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Applicants',
                  count: '145',
                  icon: Icons.people_outline,
                  color: AppColors.purple,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Closed',
                  count: '4',
                  icon: Icons.lock_outline,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Applicants Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Applicants', style: textTheme.headlineMedium),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 16),
          ApplicantCard(
            name: 'Alice Smith',
            jobTitle: 'Senior UI/UX Designer',
            status: 'Interview',
            appliedDate: '2 days ago',
            onTap: () {},
          ),
          const SizedBox(height: 32),

          // Active Postings Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Postings', style: textTheme.headlineMedium),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<PostgrestList>(
            future: _jobsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              }

              final allJobs = snapshot.data ?? [];
              // Filter only active jobs
              final activeJobs = allJobs
                  .where((job) => job['is_active'] == true)
                  .toList();

              if (activeJobs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 48,
                          color: theme.hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active postings',
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeJobs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final job = activeJobs[index];
                  return EmployerJobCard(
                    job: job,
                    afterEdit: _refreshJobs,
                    onClose: () => _toggleJobStatus(job),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
