import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final ApplicationService _applicationService = ApplicationService();
  late Future<List<Map<String, dynamic>>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _applicationService.fetchMyApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final applications = snapshot.data ?? [];

          if (applications.isEmpty) {
            return const Center(
              child: Text('You haven\'t applied to any jobs yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final app = applications[index];
              // The application object usually contains the 'job_posts' relation.
              // We need to ensure logic handles this.
              final job = app['job_posts'] as Map<String, dynamic>;
              // We might want to show the application status on the card.
              // UnifiedJobCard might not show status by default unless configured.
              // For now we just pass the job.
              // If we want to show specific status like "Pending", we might need a custom view or update UnifiedJobCard.

              // Assuming UnifiedJobCard can show status if we pass it or if we wrap it.
              // But let's check UnifiedJobCard later. For now, basic list.
              return UnifiedJobCard(
                job: job,
                role: JobCardRole.seeker,
                canApply: false, // Already applied
                // status: app['status'], // If UnifiedJobCard supported it
              );
            },
          );
        },
      ),
    );
  }
}
