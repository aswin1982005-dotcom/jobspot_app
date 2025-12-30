import 'package:flutter/material.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/widgets/employer_job_card.dart';
import 'package:jobspot_app/features/jobs/create_job_screen.dart';

class JobPostingTab extends StatelessWidget {
  const JobPostingTab({super.key});

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
            // Fixed Header
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
            // Scrollable Content
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
                    // Job Cards
                    EmployerJobCard(
                      company: 'Google Inc.',
                      position: 'Senior UI/UX Designer',
                      location: 'California, USA',
                      salary: '\$120k - \$150k',
                      type: 'Full Time',
                      logo: Icons.g_mobiledata,
                      logoColor: colorScheme.primary,
                      status: 'open',
                      onEdit: () {},
                      onClose: () {},
                    ),
                    const SizedBox(height: 12),
                    EmployerJobCard(
                      company: 'Apple Inc.',
                      position: 'Product Manager',
                      location: 'New York, USA',
                      salary: '\$140k - \$180k',
                      type: 'Full Time',
                      logo: Icons.apple,
                      logoColor: colorScheme.secondary,
                      status: 'open',
                      onEdit: () {},
                      onClose: () {},
                    ),
                    const SizedBox(height: 12),
                    EmployerJobCard(
                      company: 'Microsoft',
                      position: 'Software Engineer',
                      location: 'Seattle, USA',
                      salary: '\$110k - \$145k',
                      type: 'Remote',
                      logo: Icons.business,
                      logoColor: colorScheme.primary,
                      status: 'closed',
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
        // Fixed FAB
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => _navigateToCreateJob(context),
            backgroundColor: colorScheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
