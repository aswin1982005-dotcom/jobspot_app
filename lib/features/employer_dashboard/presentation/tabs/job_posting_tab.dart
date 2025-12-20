import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/widgets/employer_job_card.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/widgets/create_job_dialog.dart';

class JobPostingTab extends StatelessWidget {
  const JobPostingTab({super.key});

  void _showCreateJobDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap Post or Close
      builder: (context) => const CreateJobDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.whiteBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateJobDialog(context),
        backgroundColor: AppColors.darkPurple,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        'Manage your',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Job Postings', style: textTheme.headlineLarge),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.notifications_outlined, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Postings', style: textTheme.headlineMedium),
                  TextButton(onPressed: () {}, child: const Text('Filter')),
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
                logoColor: AppColors.purple,
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
                logoColor: AppColors.orange,
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
                logoColor: AppColors.purple,
                status: 'closed',
                onEdit: () {},
                onClose: () {},
              ),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }
}
