import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/seeker_home_provider.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab>
    with AutomaticKeepAliveClientMixin {
  PostgrestList _allJobs = [];
  PostgrestList filteredJobs = [];
  bool _isLoading = true;
  List<Map<String, dynamic>>? _lastJobs;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWithProvider();
  }

  void _syncWithProvider() {
    final provider = Provider.of<SeekerHomeProvider>(context);
    if (provider.recommendedJobs != _lastJobs) {
      _lastJobs = provider.recommendedJobs;
      setState(() {
        _allJobs = provider.recommendedJobs;
        _isLoading = false;
      });
      _filterJobs();
    }
  }

  // Refresh now just asks provider to reload
  void _refresh() {
    Provider.of<SeekerHomeProvider>(context, listen: false).refresh();
  }

  String? _selectedJobType;
  String _searchQuery = '';
  String _sortOption = 'Newest'; // Newest, Salary High-Low, Salary Low-High

  final List<String> _jobTypes = [
    'Full Time',
    'Part Time',
    'Remote',
    'Contract',
  ];

  void _filterJobs({String? query}) {
    if (query != null) {
      _searchQuery = query;
    }

    setState(() {
      // 1. Filter by Job Type
      List<dynamic> temp = _allJobs;
      if (_selectedJobType != null) {
        temp = temp.where((job) => job['type'] == _selectedJobType).toList();
      }

      // 2. Filter by Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        temp = temp.where((job) {
          final title = (job['title'] as String?)?.toLowerCase() ?? '';
          final company = (job['company'] as String?)?.toLowerCase() ?? '';
          // Assuming company is a string name, but if it's a relation/map, we need to handle that.
          // Often companies are relations. Checking basic fields first.
          return title.contains(q) || company.contains(q);
        }).toList();
      }

      // 3. Sort
      if (_sortOption == 'Newest') {
        temp.sort((a, b) {
          final da = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
          final db = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
          return db.compareTo(da);
        });
      } else if (_sortOption == 'Salary High-Low') {
        // Assuming logic for salary exists
      }

      filteredJobs = temp.cast<Map<String, dynamic>>();
    });
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
              Text('Sort Jobs', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Newest'),
                trailing: _sortOption == 'Newest'
                    ? const Icon(Icons.check, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => _sortOption = 'Newest');
                  _filterJobs();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Oldest'),
                trailing: _sortOption == 'Oldest'
                    ? const Icon(Icons.check, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => _sortOption = 'Oldest');
                  _filterJobs();
                  Navigator.pop(context);
                },
              ),
              // Add salary sort if data supports it
            ],
          ),
        );
      },
    );
  }

  void _openFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Job Type',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _jobTypes.map((type) {
                      final isSelected = _selectedJobType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedJobType = selected ? type : null;
                          });
                          _filterJobs();
                          Navigator.pop(context);
                        },
                        backgroundColor: Theme.of(context).cardColor,
                        selectedColor: AppColors.purple,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header & Search Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Jobs',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) => _filterJobs(query: value),
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Job title, company, or keywords...',
                        hintStyle: TextStyle(
                          color: theme.hintColor.withValues(alpha: 0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.primaryColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton(
                          'Filter',
                          Icons.tune_rounded,
                          _openFilterOptions,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterButton(
                          'Sort',
                          Icons.sort_rounded,
                          _openSortOptions,
                        ),
                        if (_selectedJobType != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.purple.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _selectedJobType!,
                                  style: const TextStyle(
                                    color: AppColors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    _selectedJobType = null;
                                    _filterJobs();
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results Area
            Expanded(
              child:
                  _isLoading ||
                      context.select<SeekerHomeProvider, bool>(
                        (p) => p.isLoading,
                      )
                  ? const Center(child: CircularProgressIndicator())
                  : filteredJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No jobs found',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.hintColor,
                            ),
                          ),
                          Text(
                            'Try adjusting your search or filters',
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filteredJobs.length} Results',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _sortOption,
                                style: textTheme.bodySmall?.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: filteredJobs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final job = filteredJobs[index];
                              final provider = Provider.of<SeekerHomeProvider>(
                                context,
                                listen: false,
                              );
                              final isApplied = provider.isJobApplied(
                                job['id'],
                              );
                              return UnifiedJobCard(
                                job: job,
                                role: JobCardRole.seeker,
                                canApply: !isApplied,
                                onApplied: _refresh,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
