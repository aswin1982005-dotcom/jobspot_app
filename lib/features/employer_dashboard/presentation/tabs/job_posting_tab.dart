import 'package:flutter/material.dart';
import 'package:jobspot_app/features/jobs/presentation/employer_job_card.dart';
import 'package:jobspot_app/features/jobs/create_job_screen.dart';

/// A tab widget for the employer dashboard that allows employers to manage their job postings.
///
/// It displays a list of jobs with their current status (open/closed) and
/// provides functionality to create new jobs, filter existing ones, and perform
/// actions like editing or closing a posting.
class JobPostingTab extends StatelessWidget {
  /// Creates a [JobPostingTab].
  const JobPostingTab({super.key});

  /// Navigates to the [CreateJobScreen] where the employer can fill out
  /// details for a new job opening.
  ///
  /// The [context] is used to find the [Navigator].
  void _navigateToCreateJob(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateJobScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            /// Fixed header containing the title and notifications icon.
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
            ),
            const SizedBox(height: 24),

            /// Scrollable content area containing the list of job postings.
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Postings',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list, size: 20),
                          label: const Text('Filter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// List of job cards. In a real application, these would be
                    /// dynamically generated from a list of jobs.
                    EmployerJobCard(
                      job: const {
                        'title': 'Senior UI/UX Designer',
                        'work_mode': 'On-site',
                        'location': 'California, USA',
                        'pay_amount_min': 120000,
                        'pay_amount_max': 150000,
                        'pay_type': 'yearly',
                        'is_active': true,
                        'same_day_pay': true,
                      },
                      onEdit: () {},
                      onClose: () {},
                    ),
                    const SizedBox(height: 12),
                    EmployerJobCard(
                      job: const {
                        'title': 'Senior UI/UX Designer',
                        'work_mode': 'On-site',
                        'location': 'California, USA',
                        'pay_amount_min': 120000,
                        'pay_amount_max': 150000,
                        'pay_type': 'yearly',
                        'is_active': true,
                        'same_day_pay': true,
                      },
                      onEdit: () {},
                      onClose: () {},
                    ),
                    const SizedBox(height: 12),
                    EmployerJobCard(
                      job: const {
                        'title': 'Senior UI/UX Designer',
                        'work_mode': 'onsite',
                        'location': 'California, USA',
                        'pay_amount_min': 120000,
                        'pay_amount_max': 150000,
                        'pay_type': 'yearly',
                        'is_active': true,
                        'same_day_pay': true,
                      },
                      onEdit: () {},
                      onClose: () {},
                    ),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),

        /// Floating action button to create a new job posting.
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
  }
}
