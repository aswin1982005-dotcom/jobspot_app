import 'package:flutter/material.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';
import 'package:jobspot_app/features/jobs/presentation//create_job_screen.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobPostingTab extends StatelessWidget {
  final PostgrestList jobs;
  final Future<void> Function() onRefresh;

  const JobPostingTab({super.key, required this.jobs, required this.onRefresh});

  void _navigateToCreateJob(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateJobScreen()),
    );
    if (result == true) {
      onRefresh();
    }
  }

  Future<void> _toggleJobStatus(
    BuildContext context,
    Map<String, dynamic> job,
  ) async {
    final bool currentStatus = job['is_active'] ?? true;
    try {
      await JobService().updateJobPost(job['id'], {
        'is_active': !currentStatus,
      });
      onRefresh();
    } catch (e) {
      if (context.mounted) {
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
              child: jobs.isEmpty
                  ? ListView(
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
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: jobs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return UnifiedJobCard(
                          job: job,
                          role: JobCardRole.employer,
                          afterEdit: () {},
                          onClose: () => _toggleJobStatus(context, job),
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
