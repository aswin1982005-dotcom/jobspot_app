import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';
import 'package:jobspot_app/features/jobs/presentation/job_list_screen.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/seeker_home_provider.dart';
import 'package:jobspot_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:jobspot_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:jobspot_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:provider/provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Consumer<SeekerHomeProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(child: Text('Error: ${provider.error}'));
            }

            final savedJobs = provider.savedJobs;
            final recommendedJobs = provider.recommendedJobs;

            final appliedCount = provider.appliedCount;
            final interviewCount = provider.interviewCount;
            final selectedCount = provider.selectedCount;

            final providerProfile = context.watch<ProfileProvider>();
            final userName =
                providerProfile.profileData?['full_name'] ?? 'User';

            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              'Hello, $userName 👋',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find your dream job today',
                              style: textTheme.bodyLarge?.copyWith(
                                color: theme.hintColor,
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
                                color: theme.dividerColor.withValues(
                                  alpha: 0.5,
                                ),
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
                            'Applied',
                            appliedCount,
                            Icons.send_rounded,
                            AppColors.sky,
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            'Interviews',
                            interviewCount,
                            Icons.videocam_rounded,
                            AppColors.sunny,
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            'Selected',
                            selectedCount,
                            Icons.check_circle_rounded,
                            AppColors.teal,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Saved Jobs Section (Horizontal)
                    if (savedJobs.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved Jobs',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final jobsList = savedJobs
                                  .map(
                                    (s) =>
                                        s['job_posts'] as Map<String, dynamic>,
                                  )
                                  .toList();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JobListScreen(
                                    title: 'Saved Jobs',
                                    jobs: jobsList,
                                    appliedJobIds: provider.appliedJobIds,
                                    onRefresh: () async => provider.refresh(),
                                  ),
                                ),
                              );
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 240, // Increased height to prevent overflow
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: savedJobs.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final job =
                                savedJobs[index]['job_posts']
                                    as Map<String, dynamic>;
                            final jobId = job['id'] as String;
                            final isApplied = provider.isJobApplied(jobId);
                            return SizedBox(
                              width: 300,
                              child: UnifiedJobCard(
                                job: job,
                                role: JobCardRole.seeker,
                                canApply: !isApplied,
                                onApplied: provider.refresh,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Recommended Jobs (Vertical Feed)
                    Text(
                      'Recommended for you',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (recommendedJobs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 48,
                                color: theme.dividerColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No jobs found yet",
                                style: TextStyle(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recommendedJobs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final job = recommendedJobs[index];
                          final jobId = job['id'] as String;
                          final isApplied = provider.isJobApplied(jobId);
                          return UnifiedJobCard(
                            job: job,
                            role: JobCardRole.seeker,
                            canApply: !isApplied,
                            onApplied: provider.refresh,
                          );
                        },
                      ),
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
