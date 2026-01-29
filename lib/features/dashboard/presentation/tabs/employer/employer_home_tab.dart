import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        companyName,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Consumer<NotificationProvider>(
                        builder: (context, notifProvider, child) {
                          return Badge(
                            label: notifProvider.unreadCount > 0
                                ? Text('${notifProvider.unreadCount}')
                                : null,
                            isLabelVisible: notifProvider.unreadCount > 0,
                            child: Icon(
                              Icons.notifications_outlined,
                              color: theme.iconTheme.color,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Unified Stats Dashboard
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkPurple,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      'Active Jobs',
                      activeJobsCount,
                      Icons.check_circle_rounded,
                      AppColors.teal,
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      'Applicants',
                      totalApplicants,
                      Icons.people_alt_rounded,
                      AppColors.sky,
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      'Closed',
                      closedJobsCount,
                      Icons.lock_rounded,
                      AppColors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recent Applicants Section
              if (recentApplicants.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Applicants',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('See All')),
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
                const SizedBox(height: 24),
              ],

              // Active Postings Section
              Text(
                'Active Postings',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (activePostings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dashboard_customize_outlined,
                          size: 48,
                          color: theme.dividerColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active jobs',
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
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}
