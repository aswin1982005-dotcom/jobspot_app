import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/seeker_dashboard/presentation/widgets/stat_card.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/widgets/employer_job_card.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/widgets/applicant_card.dart';

class EmployerHomeTab extends StatelessWidget {
  const EmployerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10), // Compensation for removed SafeArea
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
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Google Inc.', style: textTheme.headlineLarge),
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
                child: const Icon(Icons.notifications_outlined, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stats Cards
          const Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Active Jobs',
                  count: '12',
                  icon: Icons.check_circle_outline,
                  color: Color(0xFF01B307),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Applicants',
                  count: '145',
                  icon: Icons.people_outline,
                  color: AppColors.purple,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Closed',
                  count: '4',
                  icon: Icons.lock_outline,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Applicants Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Applicants', style: textTheme.headlineMedium),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 16),
          ApplicantCard(
            name: 'Alice Smith',
            jobTitle: 'Senior UI/UX Designer',
            status: 'Interview',
            appliedDate: '2 days ago',
            onTap: () {},
          ),
          const SizedBox(height: 12),

          // Recent Postings Section
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Postings', style: textTheme.headlineMedium),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}
