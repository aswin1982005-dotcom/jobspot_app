import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with AutomaticKeepAliveClientMixin {
  final ApplicationService _applicationService = ApplicationService();
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _sortOption = 'Newest';

  final List<String> _filters = [
    'All',
    'Pending',
    'Interview',
    'Offer',
    'Rejected',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _applicationService.fetchMyApplications();
  }

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
                'Sort Applications',
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

  List<Map<String, dynamic>> _filterApplications(
    List<Map<String, dynamic>> apps,
  ) {
    var filtered = List<Map<String, dynamic>>.from(apps);

    // 1. Search (Job Title)
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((app) {
        final job = app['job_posts'] as Map<String, dynamic>;
        final title = (job['title'] as String?)?.toLowerCase() ?? '';
        return title.contains(query);
      }).toList();
    }

    // 2. Filter (Status)
    if (_selectedFilter != 'All') {
      filtered = filtered.where((app) {
        final status = (app['status'] as String?)?.toLowerCase() ?? '';
        return status == _selectedFilter.toLowerCase();
      }).toList();
    }

    // 3. Sort (Date Applied)
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['applied_at'] ?? '') ?? DateTime(0);
      final dateB = DateTime.tryParse(b['applied_at'] ?? '') ?? DateTime(0);
      if (_sortOption == 'Newest') {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allApplications = snapshot.data ?? [];
          final displayedApplications = _filterApplications(allApplications);

          return Column(
            children: [
              // Search and Filter Header
              Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search applications...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _filters.map((filter) {
                                final isSelected = _selectedFilter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(filter),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(
                                          () => _selectedFilter = filter,
                                        );
                                      }
                                    },
                                    backgroundColor: theme.cardColor,
                                    selectedColor: AppColors.purple,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : theme.textTheme.bodyLarge?.color,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: Colors.grey.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    showCheckmark: false,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _openSortOptions,
                          icon: const Icon(Icons.sort),
                          tooltip: 'Sort',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: displayedApplications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: theme.hintColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              allApplications.isEmpty
                                  ? 'You haven\'t applied to any jobs yet.'
                                  : 'No applications match your search.',
                              style: TextStyle(color: theme.hintColor),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedApplications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final app = displayedApplications[index];
                          final job = app['job_posts'] as Map<String, dynamic>;

                          return Stack(
                            children: [
                              UnifiedJobCard(
                                job: job,
                                role: JobCardRole.seeker,
                                canApply: false,
                                showBookmark: false,
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: _buildStatusChip(
                                  app['status'] ?? 'pending',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'offer':
      case 'hired':
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'interview':
      case 'shortlisted':
        color = AppColors.purple;
        break;
      case 'pending':
        color = AppColors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
