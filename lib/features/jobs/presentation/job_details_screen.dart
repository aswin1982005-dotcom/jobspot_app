import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:jobspot_app/features/jobs/presentation/create_job_screen.dart';

/// A screen that displays detailed information about a job posting.
///
/// It adapts its UI based on whether the viewer is a 'seeker' or an 'employer'.
/// Seekers see an "Apply Now" button, while employers see "Edit" and "Close" actions.
class JobDetailsScreen extends StatefulWidget {
  /// The job data to display.
  final Map<String, dynamic> job;

  /// The role of the current user ('seeker' or 'employer').
  final String userRole;

  /// Whether the seeker has already applied for this job.
  final bool isApplied;

  /// Callback when the job is applied for (seeker only).
  final VoidCallback? onApplied;

  /// Callback when the job is edited or closed (employer only).
  final VoidCallback? onJobChanged;

  const JobDetailsScreen({
    super.key,
    required this.job,
    required this.userRole,
    this.isApplied = false,
    this.onApplied,
    this.onJobChanged,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final JobService _jobService = JobService();
  final ApplicationService _applicationService = ApplicationService();

  bool _isBookmarked = false;
  bool _isApplying = false;
  late bool _hasApplied;
  late Map<String, dynamic> _currentJob;

  @override
  void initState() {
    super.initState();
    _currentJob = Map.from(widget.job);
    _hasApplied = widget.isApplied;
    if (widget.userRole == 'seeker') {
      _checkSavedStatus();
    }
  }

  Future<void> _checkSavedStatus() async {
    final jobId = _currentJob['id'];
    if (jobId == null) return;
    try {
      final isSaved = await _jobService.isJobSaved(jobId);
      if (mounted) {
        setState(() => _isBookmarked = isSaved);
      }
    } catch (e) {
      debugPrint('Error checking saved status: $e');
    }
  }

  Future<void> _toggleSave() async {
    final jobId = _currentJob['id'];
    if (jobId == null) return;

    final previousStatus = _isBookmarked;
    setState(() => _isBookmarked = !previousStatus);

    try {
      await _jobService.toggleSaveJob(jobId, previousStatus);
    } catch (e) {
      if (mounted) {
        setState(() => _isBookmarked = previousStatus);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving job: $e')));
      }
    }
  }

  Future<void> _applyJob() async {
    if (_isApplying || _hasApplied) return;

    setState(() => _isApplying = true);
    try {
      await _applicationService.fastApply(
        jobPostId: _currentJob['id'],
        message: "Applied from Job Details Screen",
      );
      if (mounted) {
        setState(() => _hasApplied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application sent successfully!')),
        );
      }
      widget.onApplied?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error applying for job: $e')));
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _toggleJobStatus() async {
    final jobId = _currentJob['id'];
    if (jobId == null) return;

    final bool currentActive = _currentJob['is_active'] ?? true;
    final bool newStatus = !currentActive;

    try {
      await _jobService.updateJobStatus(jobId, newStatus);
      setState(() {
        _currentJob['is_active'] = newStatus;
      });
      widget.onJobChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newStatus ? 'Job reopened' : 'Job closed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job status: $e')),
        );
      }
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateJobScreen(job: _currentJob),
      ),
    );
    if (result == true && mounted) {
      widget.onJobChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final isEmployer = widget.userRole == 'employer';
    final isActive = _currentJob['is_active'] ?? true;
    final isSameDayPay = _currentJob['same_day_pay'] == true;

    // Formatting Salary
    final minPay = _currentJob['pay_amount_min'] ?? 0;
    final maxPay = _currentJob['pay_amount_max'];
    final payType = _currentJob['pay_type']?.toString().toUpperCase() ?? '';
    final salaryStr = maxPay != null ? '₹$minPay - ₹$maxPay' : '₹$minPay';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: theme.cardColor,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.business,
                      color: colorScheme.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentJob['title'] ?? 'Untitled Position',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentJob['location'] ?? 'Remote',
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildInfoChip(
                        context,
                        _currentJob['work_mode'] ?? 'Remote',
                      ),
                      _buildInfoChip(context, payType.replaceAll('_', ' ')),
                      if (isSameDayPay) _buildSameDayPayBadge(colorScheme),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Salary'),
                  Text(
                    salaryStr,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Job Description'),
                  Text(
                    _currentJob['description'] ?? 'No description provided.',
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle(context, 'Schedule'),
                  _buildInfoRow(
                    context,
                    Icons.calendar_today_outlined,
                    'Working Days',
                    (_currentJob['working_days'] as List?)?.join(', ') ??
                        'Not specified',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.access_time,
                    'Shift Hours',
                    '${_currentJob['shift_start']?.toString().substring(0, 5) ?? '09:00'} - ${_currentJob['shift_end']?.toString().substring(0, 5) ?? '18:00'}',
                  ),
                  const SizedBox(height: 24),

                  if (_currentJob['requirements'] != null &&
                      (_currentJob['requirements'] as List).isNotEmpty) ...[
                    _buildSectionTitle(context, 'Requirements'),
                    ...(_currentJob['requirements'] as List).map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(child: Text(req.toString())),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            if (!isEmployer) ...[
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  ),
                  color: colorScheme.secondary,
                  onPressed: _toggleSave,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (isActive && !_isApplying && !_hasApplied)
                      ? _applyJob
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isApplying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          !isActive
                              ? 'Job Closed'
                              : (_hasApplied ? 'Applied' : 'Apply Now'),
                        ),
                ),
              ),
            ] else ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _toggleJobStatus,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: isActive ? colorScheme.error : colorScheme.primary,
                    ),
                    foregroundColor: isActive
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                  child: Text(isActive ? 'Close Posting' : 'Reopen Posting'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToEdit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Edit Posting'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).cardColor,
      labelStyle: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildSameDayPayBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 16, color: colorScheme.secondary),
          const SizedBox(width: 4),
          const Text(
            'SAME DAY PAY',
            style: TextStyle(
              color: Color(0xFFE67E22),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
