import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/features/jobs/presentation/job_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/services/job_service.dart';

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
  final List<String> _jobTypes = [
    'Full Time',
    'Part Time',
    'Remote',
    'Contract',
  ];

  void _filterJobs() {
    setState(() {
      if (_selectedJobType == null) {
        filteredJobs = List.from(_allJobs);
      } else {
        filteredJobs = _allJobs
            .where((job) => job['type'] == _selectedJobType)
            .toList();
      }
    });
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
                          onPressed: () {},
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
                        'Sort by: Newest',
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

                        return JobCard(
                          job: job,
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
