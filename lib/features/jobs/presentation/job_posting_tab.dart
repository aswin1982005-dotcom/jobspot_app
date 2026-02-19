import 'package:flutter/material.dart';
import 'package:jobspot_app/core/utils/global_refresh_manager.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';
import 'package:jobspot_app/features/jobs/presentation/create_job_screen.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/employer_home_provider.dart';

class JobPostingTab extends StatefulWidget {
  const JobPostingTab({super.key});

  @override
  State<JobPostingTab> createState() => _JobPostingTabState();
}

class _JobPostingTabState extends State<JobPostingTab> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All'; // All, Active, Closed
  String _sortOption = 'Newest'; // Newest, Oldest

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToCreateJob(BuildContext context) async {
    final provider = context.read<EmployerHomeProvider>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateJobScreen()),
    );
    if (result != null) {
      if (result is Map<String, dynamic>) {
        provider.addJob(result);
      } else {
        provider.refresh();
      }
    }
  }

  Future<void> _toggleJobStatus(
    BuildContext context,
    Map<String, dynamic> job,
  ) async {
    final provider = context.read<EmployerHomeProvider>();
    final bool currentStatus = job['is_active'] ?? true;
    try {
      await JobService().updateJobPost(job['id'], {
        'is_active': !currentStatus,
      });
      // Update local state instead of full refresh
      final updatedJob = Map<String, dynamic>.from(job);
      updatedJob['is_active'] = !currentStatus;
      provider.updateJob(updatedJob);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job status: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filterJobs(List<dynamic> allJobs) {
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(
      allJobs,
    );

    // 1. Search (Title)
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((job) {
        final title = (job['title'] as String?)?.toLowerCase() ?? '';
        return title.contains(query);
      }).toList();
    }

    // 2. Filter (Status)
    if (_filterStatus != 'All') {
      final bool isActive = _filterStatus == 'Active';
      filtered = filtered.where((job) {
        return (job['is_active'] ?? true) == isActive;
      }).toList();
    }

    // 3. Sort
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
      if (_sortOption == 'Newest') {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });

    return filtered;
  }

  void _openSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort Jobs', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Newest Created'),
                trailing: _sortOption == 'Newest'
                    ? const Icon(Icons.check, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => _sortOption = 'Newest');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Oldest Created'),
                trailing: _sortOption == 'Oldest'
                    ? const Icon(Icons.check, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => _sortOption = 'Oldest');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Consumer<EmployerHomeProvider>(
      builder: (context, provider, _) {
        final jobs = _filterJobs(provider.jobs);

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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                GlobalRefreshManager.refreshAll(context),
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh',
                          ),
                          const SizedBox(width: 8),
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search job titles...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filters and Sort
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Active', 'Closed'].map((status) {
                              final isSelected = _filterStatus == status;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(status),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _filterStatus = status);
                                    }
                                  },
                                  backgroundColor: theme.cardColor,
                                  selectedColor: AppColors.purple,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : theme.textTheme.bodyLarge?.color,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  showCheckmark: false,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _openSortOptions,
                        icon: const Icon(Icons.sort),
                        tooltip: 'Sort Jobs',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                                    'No job postings found',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                  if (_searchController.text.isEmpty &&
                                      _filterStatus == 'All') ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _navigateToCreateJob(context),
                                      child: const Text('Post a Job'),
                                    ),
                                  ],
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
                              afterEdit: (updatedJob) {
                                provider.updateJob(updatedJob);
                              },
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
      },
    );
  }
}
