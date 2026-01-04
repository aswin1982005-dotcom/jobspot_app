import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/data/services/job_service.dart';
import 'package:jobspot_app/features/jobs/presentation/job_details_screen.dart';
import 'package:jobspot_app/features/jobs/presentation/create_job_screen.dart';
import 'package:jobspot_app/features/jobs/presentation/widgets/job_card_header.dart';
import 'package:jobspot_app/features/jobs/presentation/widgets/job_card_schedule_info.dart';
import 'package:jobspot_app/features/jobs/presentation/widgets/job_card_salary_info.dart';

enum JobCardRole { seeker, employer }

class UnifiedJobCard extends StatefulWidget {
  final Map<String, dynamic> job;
  final JobCardRole role;
  
  // Seeker specific
  final bool canApply;
  final VoidCallback? onApplied;

  // Employer specific
  final VoidCallback? afterEdit;
  final VoidCallback? onClose;

  const UnifiedJobCard({
    super.key,
    required this.job,
    required this.role,
    this.canApply = true,
    this.onApplied,
    this.afterEdit,
    this.onClose,
  });

  @override
  State<UnifiedJobCard> createState() => _UnifiedJobCardState();
}

class _UnifiedJobCardState extends State<UnifiedJobCard> {
  bool _isBookmarked = false;
  bool _isApplying = false;
  final JobService _jobService = JobService();

  @override
  void initState() {
    super.initState();
    if (widget.role == JobCardRole.seeker) {
      _checkSavedStatus();
    }
  }

  Future<void> _checkSavedStatus() async {
    if (widget.job['id'] == null) return;
    final isSaved = await _jobService.isJobSaved(widget.job['id']);
    if (mounted) {
      setState(() => _isBookmarked = isSaved);
    }
  }

  Future<void> _toggleSave() async {
    final jobId = widget.job['id'];
    if (jobId == null) return;

    final previousStatus = _isBookmarked;
    setState(() => _isBookmarked = !previousStatus);

    try {
      await _jobService.toggleSaveJob(jobId, previousStatus);
    } catch (e) {
      if (mounted) {
        setState(() => _isBookmarked = previousStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
    }
  }

  Future<void> _applyJob() async {
    setState(() => _isApplying = true);
    try {
      await ApplicationService().fastApply(
        jobPostId: widget.job['id'],
        message: "hello",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application sent successfully!')),
        );
      }
      widget.onApplied?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying for job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  void _navigateToCreateJob() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateJobScreen(job: widget.job)),
    );
    if (result == true) {
      widget.afterEdit?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEmployer = widget.role == JobCardRole.employer;
    final isActive = widget.job['is_active'] ?? true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(
              job: widget.job,
              userRole: isEmployer ? 'employer' : 'seeker',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobCardHeader(
              job: widget.job,
              iconSize: isEmployer ? 32 : 24,
              trailing: isEmployer 
                  ? _buildStatusBadge(isActive)
                  : IconButton(
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        color: _isBookmarked ? colorScheme.secondary : null,
                      ),
                      onPressed: _toggleSave,
                    ),
            ),
            const SizedBox(height: 16),
            if (!isEmployer) ...[
              JobCardScheduleInfo(job: widget.job),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                JobCardSalaryInfo(job: widget.job),
                if (isEmployer && widget.job['same_day_pay'] == true) 
                   _buildSameDayPayBadge(colorScheme),
                if (!isEmployer)
                  _buildSeekerAction(colorScheme),
              ],
            ),
            if (isEmployer) ...[
              const Divider(height: 32),
              _buildEmployerActions(colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'OPEN' : 'CLOSED',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSameDayPayBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, size: 14, color: colorScheme.secondary),
          const SizedBox(width: 4),
          const Text(
            'SAME DAY PAY',
            style: TextStyle(
              color: Color(0xFFE67E22), // colorScheme.secondary but more visible
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekerAction(ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: (widget.canApply && !_isApplying) ? _applyJob : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
      child: _isApplying
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(widget.canApply ? "Apply" : "Applied"),
    );
  }

  Widget _buildEmployerActions(ColorScheme colorScheme) {
    final isActive = widget.job['is_active'] ?? true;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _navigateToCreateJob,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isActive ? widget.onClose : null,
            icon: Icon(isActive ? Icons.lock_outline : Icons.lock, size: 18),
            label: Text(isActive ? 'Close' : 'Reopen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? colorScheme.error : colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
