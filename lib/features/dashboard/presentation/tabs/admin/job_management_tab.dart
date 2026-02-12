import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/job_management_provider.dart';
import 'package:provider/provider.dart';

class JobManagementTab extends StatelessWidget {
  const JobManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Consumer<JobManagementProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: Column(
            children: [
              // Filter Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Management',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            context,
                            'All Jobs',
                            provider.activeFilter == null &&
                                provider.reportedFilter == null &&
                                provider.adminDisabledFilter == null,
                            () => provider.clearFilters(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterChip(
                            context,
                            'Active',
                            provider.activeFilter == true,
                            () => provider.setActiveFilter(true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterChip(
                            context,
                            'Inactive',
                            provider.activeFilter == false,
                            () => provider.setActiveFilter(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            context,
                            'Reported',
                            provider.reportedFilter == true,
                            () => provider.setReportedFilter(true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterChip(
                            context,
                            'Disabled by Admin',
                            provider.adminDisabledFilter == true,
                            () => provider.setAdminDisabledFilter(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Job List
              Expanded(
                child: provider.jobs.isEmpty
                    ? Center(
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
                              'No jobs found',
                              style: textTheme.bodyLarge?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.jobs.length,
                        itemBuilder: (context, index) {
                          final job = provider.jobs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildJobCard(context, job, provider),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.purple
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.purple
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).hintColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    Map<String, dynamic> job,
    JobManagementProvider provider,
  ) {
    final theme = Theme.of(context);
    final isActive = job['is_active'] ?? false;
    final isReported = job['is_reported'] ?? false;
    final adminDisabled = job['admin_disabled'] ?? false;
    final jobId = job['id'] ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: adminDisabled
                        ? Colors.red.withValues(alpha: 0.1)
                        : isActive
                        ? AppColors.teal.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    adminDisabled
                        ? Icons.block
                        : isActive
                        ? Icons.check_circle
                        : Icons.archive,
                    color: adminDisabled
                        ? Colors.red
                        : isActive
                        ? AppColors.teal
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job['title'] ?? 'Job Title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isReported)
                            const Icon(
                              Icons.flag,
                              color: Colors.orange,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['company'] ?? 'Company',
                        style: TextStyle(fontSize: 14, color: theme.hintColor),
                      ),
                      Text(
                        '${job['city']}, ${job['state']}',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (job['admin_notes'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job['admin_notes'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showJobActions(context, job, provider),
                    icon: const Icon(Icons.more_horiz, size: 16),
                    label: const Text('Actions'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleJobStatus(
                      context,
                      jobId,
                      adminDisabled,
                      provider,
                    ),
                    icon: Icon(
                      adminDisabled ? Icons.check_circle : Icons.block,
                      size: 16,
                    ),
                    label: Text(adminDisabled ? 'Enable' : 'Disable'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: adminDisabled
                          ? AppColors.teal
                          : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showJobActions(
    BuildContext context,
    Map<String, dynamic> job,
    JobManagementProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Job Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Add/Edit Notes'),
              onTap: () {
                Navigator.pop(context);
                _showAddNotesDialog(context, job, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Full Details'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job details view coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('View Reports'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reports view coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNotesDialog(
    BuildContext context,
    Map<String, dynamic> job,
    JobManagementProvider provider,
  ) {
    final notesController = TextEditingController(
      text: job['admin_notes'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Notes'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Add your notes here',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.addJobNotes(job['id'], notesController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notes updated')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleJobStatus(
    BuildContext context,
    String jobId,
    bool currentlyDisabled,
    JobManagementProvider provider,
  ) {
    if (currentlyDisabled) {
      // Enable job
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Job'),
          content: const Text('Are you sure you want to enable this job?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await provider.enableJob(jobId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Job enabled')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    } else {
      // Disable job - ask for reason
      final reasonController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for disabling this job:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Reason for disabling',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a reason')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await provider.disableJob(jobId, reasonController.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Job disabled')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
    }
  }
}
