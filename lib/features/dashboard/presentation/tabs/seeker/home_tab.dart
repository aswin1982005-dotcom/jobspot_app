import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';
import 'package:jobspot_app/features/jobs/presentation/job_list_screen.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/seeker_home_provider.dart';
import 'package:provider/provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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

            // Stats from provider
            final appliedCount = provider.appliedCount;
            final interviewCount = provider.interviewCount;
            final selectedCount = provider.selectedCount;

            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Job Seeker', style: textTheme.headlineLarge),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 24,
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
                            title: 'Applied',
                            count: appliedCount.toString(),
                            icon: Icons.send,
                            color: AppColors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Interviews',
                            count: interviewCount.toString(),
                            icon: Icons.videocam,
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Selected',
                            count: selectedCount.toString(),
                            icon: Icons.check_box,
                            color: const Color(0xFF01B307),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saved Jobs', style: textTheme.headlineMedium),
                        TextButton(
                          onPressed: () {
                            // Extract the job object from the saved entry
                            final jobsList = savedJobs
                                .map(
                                  (s) => s['job_posts'] as Map<String, dynamic>,
                                )
                                .toList();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobListScreen(
                                  title: 'Saved Jobs',
                                  jobs: jobsList,
                                  onRefresh: () async => provider.refresh(),
                                ),
                              ),
                            );
                          },
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (savedJobs.isEmpty)
                      Center(
                        child: Text(
                          'No saved jobs yet',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      )
                    else
                      ...savedJobs.take(3).map((saved) {
                        final job = saved['job_posts'] as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: UnifiedJobCard(
                            job: job,
                            role: JobCardRole.seeker,
                            canApply: true,
                            onApplied: provider.refresh,
                          ),
                        );
                      }),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recommended Jobs',
                          style: textTheme.headlineMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobListScreen(
                                  title: 'Recommended Jobs',
                                  jobs: recommendedJobs,
                                  onRefresh: () async => provider.refresh(),
                                ),
                              ),
                            );
                          },
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: recommendedJobs.take(5).map((job) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 300,
                              child: UnifiedJobCard(
                                job: job,
                                role: JobCardRole.seeker,
                                canApply: true,
                                onApplied: provider.refresh,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
