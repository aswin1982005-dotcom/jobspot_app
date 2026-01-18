import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/jobs/presentation/unified_job_card.dart';

class JobListScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> jobs;
  final Future<void> Function()? onRefresh;

  const JobListScreen({
    super.key,
    required this.title,
    required this.jobs,
    this.onRefresh,
  });

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'Date';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterJobs(List<Map<String, dynamic>> jobs) {
    var filtered = List<Map<String, dynamic>>.from(jobs);

    // 1. Search (Title)
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((job) {
        final title = (job['title'] as String?)?.toLowerCase() ?? '';
        return title.contains(query);
      }).toList();
    }

    // 2. Sort
    filtered.sort((a, b) {
      if (_sortOption == 'Salary High-Low') {
        final payA = (a['pay_amount_max'] as num?) ?? 0;
        final payB = (b['pay_amount_max'] as num?) ?? 0;
        return payB.compareTo(payA);
      } else {
        // Default Date
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      }
    });

    return filtered;
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
                title: const Text('Data Posted (Newest)'),
                trailing: _sortOption == 'Date'
                    ? const Icon(Icons.check, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => _sortOption = 'Date');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Salary (High-Low)'),
                trailing: _sortOption == 'Salary High-Low'
                    ? const Icon(Icons.check, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => _sortOption = 'Salary High-Low');
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
    final displayedJobs = _filterJobs(widget.jobs);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          // Search and Sort Header
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _openSortOptions,
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: displayedJobs.isEmpty
                ? const Center(child: Text('No jobs found'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedJobs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final job = displayedJobs[index];
                      return UnifiedJobCard(
                        job: job,
                        role: JobCardRole.seeker,
                        canApply: true,
                        onApplied: widget.onRefresh,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
