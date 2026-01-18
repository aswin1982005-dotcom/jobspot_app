import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/applications/applicant_card.dart';
import 'package:jobspot_app/features/applications/presentation/applicant_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/employer_home_provider.dart';

class ApplicantsTab extends StatefulWidget {
  const ApplicantsTab({super.key});

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

  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'Newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              Text(
                'Sort Applicants',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Newest Applied'),
                trailing: _sortOption == 'Newest'
                    ? const Icon(Icons.check, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => _sortOption = 'Newest');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Oldest Applied'),
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

    return Consumer<EmployerHomeProvider>(
      builder: (context, provider, _) {
        final applications = provider.applications;

        // 1. Filter by Status
        var filteredList = _selectedFilter == 'All'
            ? applications
            : applications
                  .where((app) => app['status'] == _selectedFilter)
                  .toList();

        // 2. Filter by Search (Applicant Name or Job Title)
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          filteredList = filteredList.where((app) {
            final job = app['job_posts'] as Map<String, dynamic>?;
            final applicant = app['applicant'] as Map<String, dynamic>?;
            final name =
                (applicant?['full_name'] as String?)?.toLowerCase() ?? '';
            final jobTitle = (job?['title'] as String?)?.toLowerCase() ?? '';
            return name.contains(query) || jobTitle.contains(query);
          }).toList();
        }

        // 3. Sort
        filteredList.sort((a, b) {
          final dateA = DateTime.tryParse(a['applied_at'] ?? '') ?? DateTime(0);
          final dateB = DateTime.tryParse(b['applied_at'] ?? '') ?? DateTime(0);
          if (_sortOption == 'Newest') {
            return dateB.compareTo(dateA);
          } else {
            return dateA.compareTo(dateB);
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review your',
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Applicants', style: textTheme.headlineLarge),
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
                          color: theme.colorScheme.onSurface,
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
                  hintText: 'Search by name or position...',
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
            // Filter Chips and Sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                filter[0].toUpperCase() + filter.substring(1),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              backgroundColor: theme.cardColor,
                              selectedColor: AppColors.purple,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : textTheme.bodyLarge?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _openSortOptions,
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort Applicants',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredList.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: theme.hintColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No applicants found',
                                style: textTheme.titleMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filteredList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final app = filteredList[index];
                        final job = app['job_posts'] as Map<String, dynamic>?;
                        final applicant =
                            app['applicant'] as Map<String, dynamic>?;

                        return ApplicantCard(
                          name:
                              applicant?['full_name'] ?? 'Anonymous Applicant',
                          jobTitle: job?['title'] ?? 'Unknown Position',
                          status: app['status'] ?? 'pending',
                          appliedDate: _formatDate(app['applied_at']),
                          profileImageUrl: applicant?['avatar_url'],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ApplicantProfileScreen(application: app),
                              ),
                            );
                            // Refresh to show potentially updated status
                            provider.refresh();
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
