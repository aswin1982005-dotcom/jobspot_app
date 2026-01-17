import 'package:flutter/material.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';

class JobListScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> jobs;
  final Future<void> Function()? onRefresh;

  const JobListScreen({
    super.key,
    required this.title,
    required this.jobs,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: jobs.isEmpty
          ? const Center(child: Text('No jobs found'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = jobs[index];
                // Handle structure difference for saved jobs vs regular jobs if necessary
                // Saved jobs might be wrapped, or passed as the job map directly.
                // Assuming the caller passes a list of job maps.
                return UnifiedJobCard(
                  job: job,
                  role: JobCardRole.seeker,
                  canApply: true,
                  onApplied: onRefresh,
                );
              },
            ),
    );
  }
}
