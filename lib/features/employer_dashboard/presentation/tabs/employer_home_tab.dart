import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/seeker_dashboard/presentation/widgets/stat_card.dart';
import 'package:jobspot_app/features/jobs/presentation/employer_job_card.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/widgets/applicant_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerHomeTab extends StatelessWidget {
  final PostgrestList jobs;
  final List<Map<String, dynamic>> applications;
  final Future<void> Function() onRefresh;

  const EmployerHomeTab({
    super.key,
    required this.jobs,
    required this.applications,
    required this.onRefresh,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 7).floor()} weeks ago';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final activeJobsCount = jobs.where((j) => j['is_active'] == true).length;
    final closedJobsCount = jobs.where((j) => j['is_active'] == false).length;
    final totalApplicants = applications.length;

    final activePostings = jobs
        .where((j) => j['is_active'] == true)
        .take(3)
        .toList();
    final recentApplicants = applications.take(3).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 4),
                Text('Employer Dashboard', style: textTheme.headlineLarge),
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
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Active Jobs',
                count: activeJobsCount.toString(),
                icon: Icons.check_circle_outline,
                color: const Color(0xFF01B307),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Applicants',
                count: totalApplicants.toString(),
                icon: Icons.people_outline,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Closed',
                count: closedJobsCount.toString(),
                icon: Icons.lock_outline,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Recent Applicants Section
        if (recentApplicants.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Applicants', style: textTheme.headlineMedium),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 16),
          ...recentApplicants.map((app) {
            final job = app['job_posts'] as Map<String, dynamic>?;
            final applicant = app['applicant'] as Map<String, dynamic>?;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ApplicantCard(
                name: applicant?['full_name'] ?? 'Anonymous',
                jobTitle: job?['title'] ?? 'Position',
                status: app['status'] ?? 'pending',
                appliedDate: _formatDate(app['applied_at']),
                profileImageUrl: applicant?['avatar_url'],
                onTap: () {},
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Active Postings Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Postings', style: textTheme.headlineMedium),
            TextButton(onPressed: () {}, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 16),
        if (activePostings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.work_outline, size: 48, color: theme.hintColor),
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
          )
        else
          ...activePostings.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EmployerJobCard(
                job: job,
                afterEdit: () {},
                onClose: onRefresh,
              ),
            ),
          ),
      ],
    );
  }
}
