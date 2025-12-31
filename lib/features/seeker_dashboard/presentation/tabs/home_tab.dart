import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/seeker_dashboard/presentation/widgets/stat_card.dart';
import 'package:jobspot_app/features/jobs/presentation/job_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
                        'Welcome back!',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('John Doe', style: textTheme.headlineLarge),
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
                      title: 'Applied',
                      count: '24',
                      icon: Icons.send,
                      color: AppColors.purple,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Interviews',
                      count: '8',
                      icon: Icons.videocam,
                      color: AppColors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Selected',
                      count: '2',
                      icon: Icons.check_box,
                      color: Color(0xFF01B307),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saved Jobs', style: textTheme.headlineMedium),
                  TextButton(onPressed: () {}, child: const Text('See all')),
                ],
              ),
              const SizedBox(height: 16),
              // Job Cards
              JobCard(
                canApply: false,
                job: const {
                  'title': 'Product Manager',
                  'work_mode': 'Remote',
                  'location': 'Mumbai, India',
                  'pay_amount_min': 45000,
                  'pay_amount_max': 60000,
                  'pay_type': 'monthly',
                  'working_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                  'shift_start': '09:00:00',
                  'shift_end': '18:00:00',
                },
              ),

              const SizedBox(height: 12),
              JobCard(
                canApply: false,

                job: const {
                  'title': 'Product Manager',
                  'work_mode': 'Remote',
                  'location': 'Mumbai, India',
                  'pay_amount_min': 45000,
                  'pay_amount_max': 60000,
                  'pay_type': 'monthly',
                  'working_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                  'shift_start': '09:00:00',
                  'shift_end': '18:00:00',
                },
              ),

              const SizedBox(height: 12),
              JobCard(
                canApply: false,

                job: const {
                  'title': 'Product Manager',
                  'work_mode': 'Remote',
                  'location': 'Mumbai, India',
                  'pay_amount_min': 45000,
                  'pay_amount_max': 60000,
                  'pay_type': 'monthly',
                  'working_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                  'shift_start': '09:00:00',
                  'shift_end': '18:00:00',
                },
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recommended Jobs', style: textTheme.headlineMedium),
                  TextButton(onPressed: () {}, child: const Text('See all')),
                ],
              ),
              const SizedBox(height: 16),
              // Job Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 320, // Constrain the width of the JobCard
                      child: JobCard(
                        canApply: false,

                        job: const {
                          'title': 'Product Manager',
                          'work_mode': 'Remote',
                          'location': 'Mumbai, India',
                          'pay_amount_min': 45000,
                          'pay_amount_max': 60000,
                          'pay_type': 'monthly',
                          'working_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                          'shift_start': '09:00:00',
                          'shift_end': '18:00:00',
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 320, // Constrain the width of the JobCard
                      child: JobCard(
                        canApply: false,

                        job: const {
                          'title': 'Product Manager',
                          'work_mode': 'Remote',
                          'location': 'Mumbai, India',
                          'pay_amount_min': 45000,
                          'pay_amount_max': 60000,
                          'pay_type': 'monthly',
                          'working_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                          'shift_start': '09:00:00',
                          'shift_end': '18:00:00',
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 320, // Constrain the width of the JobCard
                      child: JobCard(
                        canApply: false,

                        job: const {
                          'title': 'Product Manager',
                          'work_mode': 'Remote',
                          'location': 'Mumbai, India',
                          'pay_amount_min': 45000,
                          'pay_amount_max': 60000,
                          'pay_type': 'monthly',
                          'working_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                          'shift_start': '09:00:00',
                          'shift_end': '18:00:00',
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
