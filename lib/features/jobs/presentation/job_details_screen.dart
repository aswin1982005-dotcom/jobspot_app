import 'package:flutter/material.dart';

import '../create_job_screen.dart';

/// A screen that displays detailed information about a job posting.
///
/// It adapts its UI based on whether the viewer is a 'seeker' or an 'employer'.
/// Seekers see an "Apply Now" button, while employers see "Edit" and "Close" actions.
class JobDetailsScreen extends StatelessWidget {
  /// The job data to display.
  final Map<String, dynamic> job;

  /// The role of the current user ('seeker' or 'employer').
  final String userRole;

  const JobDetailsScreen({
    super.key,
    required this.job,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final isEmployer = userRole == 'employer';
    final isActive = job['is_active'] ?? true;

    // Formatting Salary
    final minPay = job['pay_amount_min'] ?? 0;
    final maxPay = job['pay_amount_max'];
    final payType = job['pay_type']?.toString().toUpperCase() ?? '';
    final salaryStr = maxPay != null ? '₹$minPay - ₹$maxPay' : '₹$minPay';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: theme.cardColor,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.business,
                      color: colorScheme.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    job['title'] ?? 'Untitled Position',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job['location'] ?? 'Remote',
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildInfoChip(context, job['work_mode'] ?? 'Remote'),
                      _buildInfoChip(context, payType.replaceAll('_', ' ')),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Salary'),
                  Text(
                    salaryStr,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Job Description'),
                  Text(
                    job['description'] ??
                        'We are looking for a talented individual to join our growing team. You will be responsible for building high-quality features and collaborating with cross-functional teams.',
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Schedule'),
                  _buildInfoRow(
                    context,
                    Icons.calendar_today_outlined,
                    'Working Days',
                    (job['working_days'] as List?)?.join(', ') ??
                        'Not specified',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.access_time,
                    'Shift Hours',
                    '${job['shift_start']?.toString().substring(0, 5) ?? '09:00'} - ${job['shift_end']?.toString().substring(0, 5) ?? '18:00'}',
                  ),
                  const SizedBox(height: 24),

                  if (job['requirements'] != null) ...[
                    _buildSectionTitle(context, 'Requirements'),
                    ...(job['requirements'] as List).map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(child: Text(req)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            if (!isEmployer) ...[
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.bookmark_outline),
                  color: colorScheme.secondary,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Handle application
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Now'),
                ),
              ),
            ] else ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Handle closing job
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: isActive ? colorScheme.error : colorScheme.primary,
                    ),
                    foregroundColor: isActive
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                  child: Text(isActive ? 'Close Posting' : 'Reopen Posting'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateJobScreen(job: job),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Edit Posting'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).cardColor,
      labelStyle: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
