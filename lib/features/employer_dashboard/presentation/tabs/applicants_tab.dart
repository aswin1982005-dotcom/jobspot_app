import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/widgets/applicant_card.dart';

class ApplicantsTab extends StatefulWidget {
  const ApplicantsTab({super.key});

  @override
  State<ApplicantsTab> createState() => _ApplicantsTabState();
}

class _ApplicantsTabState extends State<ApplicantsTab> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Interview', 'Hired', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.whiteBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review your',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text('Applicants', style: textTheme.headlineLarge),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Filter Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: AppColors.white,
                    selectedColor: AppColors.purple,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    checkmarkColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: 5, // Sample count
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  // Sample data
                  final applicants = [
                    {'name': 'Alice Smith', 'job': 'Senior UI/UX Designer', 'status': 'Interview', 'date': '2 days ago'},
                    {'name': 'Bob Johnson', 'job': 'Product Manager', 'status': 'Pending', 'date': '3 days ago'},
                    {'name': 'Charlie Brown', 'job': 'Senior UI/UX Designer', 'status': 'Rejected', 'date': '4 days ago'},
                    {'name': 'David Wilson', 'job': 'Software Engineer', 'status': 'Hired', 'date': '1 week ago'},
                    {'name': 'Eve Davis', 'job': 'Software Engineer', 'status': 'Pending', 'date': '1 week ago'},
                  ];
                  
                  final applicant = applicants[index % applicants.length];
                  
                  return ApplicantCard(
                    name: applicant['name']!,
                    jobTitle: applicant['job']!,
                    status: applicant['status']!,
                    appliedDate: applicant['date']!,
                    onTap: () {
                      // TODO: Navigate to applicant details
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
