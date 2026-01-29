import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';
import 'package:jobspot_app/features/applications/applicant_card.dart';
import 'package:jobspot_app/features/applications/presentation/applicant_profile_screen.dart';
import 'package:jobspot_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/employer_home_provider.dart';
import 'package:jobspot_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:jobspot_app/features/notifications/presentation/screens/notifications_screen.dart';

class EmployerHomeTab extends StatelessWidget {
  const EmployerHomeTab({super.key});

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

    return Consumer<EmployerHomeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        final activeJobsCount = provider.activeJobsCount;
        final closedJobsCount = provider.closedJobsCount;
        final totalApplicants = provider.totalApplicants;
        final activePostings = provider.activePostings;
        final recentApplicants = provider.recentApplicants;

        final providerProfile = context.watch<ProfileProvider>();
        final companyName =
            providerProfile.profileData?['company_name'] ?? 'Employer';

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
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
                        'Welcome back,',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(companyName, style: textTheme.headlineLarge),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
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
                      child: Consumer<NotificationProvider>(
                        builder: (context, notifProvider, child) {
                          return Stack(
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                size: 24,
                              ),
                              if (notifProvider.unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 12,
                                      minHeight: 12,
                                    ),
                                    child: Text(
                                      '${notifProvider.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
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
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ApplicantProfileScreen(application: app),
                          ),
                        );
                        provider.refresh();
                      },
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
                )
              else
                ...activePostings.map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: UnifiedJobCard(
                      job: job,
                      role: JobCardRole.employer,
                      afterEdit: provider.refresh,
                      onClose: provider.refresh,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
