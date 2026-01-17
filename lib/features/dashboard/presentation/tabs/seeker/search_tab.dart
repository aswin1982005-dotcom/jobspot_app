import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:jobspot_app/data/services/job_service.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final JobService _jobService = JobService();
  final ApplicationService _applicationService = ApplicationService();
  PostgrestList _allJobs = [];
  PostgrestList filteredJobs = [];
  PostgrestList _allApplications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final jobs = await _jobService.fetchJobs();
      final applies = await _applicationService.fetchMyApplications();

      setState(() {
        _allJobs = jobs;
        filteredJobs = List.from(_allJobs);
        _allApplications = applies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching Data: $e')));
      }
    }
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Dream Job'),
        centerTitle: true,
        backgroundColor: AppColors.darkPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (value) {
                      _filterJobs(query: value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search for position, company...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ActionChip(
                          onPressed: _openFilterOptions,
                          avatar: const Icon(Icons.filter_list, size: 18),
                          label: const Text('Filter'),
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          onPressed: _openSortOptions,
                          avatar: const Icon(Icons.sort, size: 18),
                          label: const Text('Sort'),
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        if (_selectedJobType != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Chip(
                              label: Text(_selectedJobType!),
                              labelStyle: const TextStyle(color: Colors.white),
                              backgroundColor: AppColors.purple,
                              onDeleted: () {
                                _selectedJobType = null;
                                _filterJobs();
                              },
                              deleteIconColor: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredJobs.length} Jobs Found',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Sort by: $_sortOption',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: theme.hintColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No jobs found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filteredJobs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final job = filteredJobs[index];
                        final isApplied = _allApplications
                            .where(
                              (application) =>
                                  application['job_post_id'] == job['id'],
                            )
                            .isNotEmpty;

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
    );
  }
}
