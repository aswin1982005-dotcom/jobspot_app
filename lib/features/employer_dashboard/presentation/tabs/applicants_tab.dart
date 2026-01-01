import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/employer_dashboard/presentation/widgets/applicant_card.dart';

class ApplicantsTab extends StatefulWidget {
  final List<Map<String, dynamic>> applications;
  final Future<void> Function() onRefresh;

  const ApplicantsTab({
    super.key,
    required this.applications,
    required this.onRefresh,
  });

  @override
  State<ApplicantsTab> createState() => _ApplicantsTabState();
}

class _ApplicantsTabState extends State<ApplicantsTab> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'pending',
    'interview',
    'hired',
    'rejected',
  ];

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 7).floor()} weeks ago';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final filteredApplications = _selectedFilter == 'All'
        ? widget.applications
        : widget.applications
            .where((app) => app['status'] == _selectedFilter)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review your',
                style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
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
                label: Text(filter[0].toUpperCase() + filter.substring(1)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: theme.cardColor,
                selectedColor: AppColors.purple,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : textTheme.bodyLarge?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredApplications.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: theme.hintColor),
                          const SizedBox(height: 16),
                          Text(
                            'No applicants found',
                            style: textTheme.titleMedium
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: filteredApplications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final app = filteredApplications[index];
                    final job = app['job_posts'] as Map<String, dynamic>?;
                    final applicant = app['applicant'] as Map<String, dynamic>?;

                    return ApplicantCard(
                      name: applicant?['full_name'] ?? 'Anonymous Applicant',
                      jobTitle: job?['title'] ?? 'Unknown Position',
                      status: app['status'] ?? 'pending',
                      appliedDate: _formatDate(app['applied_at']),
                      profileImageUrl: applicant?['avatar_url'],
                      onTap: () {},
                    );
                  },
                ),
        ),
      ],
    );
  }
}
