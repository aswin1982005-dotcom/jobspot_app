import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/features/jobs/presentation/job_list_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final JobService _jobService = JobService();
  final ApplicationService _applicationService = ApplicationService();

  late Future<Map<String, dynamic>> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _homeDataFuture = _fetchHomeData();
    });
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    final results = await Future.wait([
      _jobService.fetchSavedJobs(),
      _jobService.fetchJobs(), // Recommended
      _applicationService.fetchMyApplications(),
    ]);

    return {
      'saved': results[0],
      'recommended': results[1],
      'applications': results[2],
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _homeDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final data = snapshot.data!;
            final savedJobs = data['saved'] as List<Map<String, dynamic>>;
            final recommendedJobs =
                data['recommended'] as List<Map<String, dynamic>>;
            final myApplications =
                data['applications'] as List<Map<String, dynamic>>;

            final appliedCount = myApplications.length;
            final interviewCount = myApplications
                .where((app) => app['status'] == 'interview')
                .length;
            final selectedCount = myApplications
                .where((app) => app['status'] == 'hired')
                .length;

            return SingleChildScrollView(
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
                                onRefresh: () async => _refreshData(),
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
                          onApplied: _refreshData,
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recommended Jobs', style: textTheme.headlineMedium),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobListScreen(
                                title: 'Recommended Jobs',
                                jobs: recommendedJobs,
                                onRefresh: () async => _refreshData(),
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
                              onApplied: _refreshData,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
