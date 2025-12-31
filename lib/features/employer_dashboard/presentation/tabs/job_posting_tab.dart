import 'package:flutter/material.dart';
import 'package:jobspot_app/features/jobs/presentation/employer_job_card.dart';
import 'package:jobspot_app/features/jobs/create_job_screen.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A tab widget for the employer dashboard that allows employers to manage their job postings.
class JobPostingTab extends StatefulWidget {
  const JobPostingTab({super.key});

  @override
  State<JobPostingTab> createState() => _JobPostingTabState();
}

class _JobPostingTabState extends State<JobPostingTab> {
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

  void _navigateToCreateJob(BuildContext context, {PostgrestMap? job}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateJobScreen(job: job)),
    );
    if (result == true) {
      _refreshJobs();
    }
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
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage your',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Job Postings', style: textTheme.headlineLarge),
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
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 24,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<PostgrestList>(
                future: _jobsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final jobs = snapshot.data ?? [];

                  if (jobs.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: theme.hintColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No job postings yet',
                                style: textTheme.titleMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _navigateToCreateJob(context),
                                child: const Text('Post a Job'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: jobs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return EmployerJobCard(
                        job: job,
                        onEdit: () {
                          _navigateToCreateJob(context, job: job);
                        },
                        onClose: () => _toggleJobStatus(job),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => _navigateToCreateJob(context),
            backgroundColor: colorScheme.primary,
            tooltip: 'Create New Job',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
