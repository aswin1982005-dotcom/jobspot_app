import 'package:flutter/material.dart';
import 'package:jobspot_app/data/services/application_service.dart';
import 'package:jobspot_app/data/services/job_service.dart';

class JobCard extends StatefulWidget {
  final Map<String, dynamic> job;
  final bool canApply;
  final VoidCallback? onApplied;

  const JobCard({
    super.key,
    required this.job,
    required this.canApply,
    this.onApplied,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isBookmarked = false;
  bool _isApplying = false;
  final JobService _jobService = JobService();

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    if (widget.job['id'] == null) return;
    final isSaved = await _jobService.isJobSaved(widget.job['id']);
    if (mounted) {
      setState(() {
        _isBookmarked = isSaved;
      });
    }
  }

  Future<void> _toggleSave() async {
    final jobId = widget.job['id'];
    if (jobId == null) return;

    final previousStatus = _isBookmarked;
    setState(() {
      _isBookmarked = !previousStatus;
    });

    try {
      await _jobService.toggleSaveJob(jobId, previousStatus);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarked = previousStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
    }
  }

  Future<void> _applyJob() async {
    setState(() {
      _isApplying = true;
    });
    try {
      final messenger = ScaffoldMessenger.of(context);
      await ApplicationService().fastApply(
        jobPostId: widget.job['id'],
        message: "hello",
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Application sent successfully!')),
      );
      if (widget.onApplied != null) {
        widget.onApplied!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error applying for job: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final job = widget.job;

    // Formatting Salary
    final minPay = job['pay_amount_min'] ?? 0;
    final maxPay = job['pay_amount_max'];
    final payType = job['pay_type'] ?? '';
    final salaryStr = maxPay != null ? '₹$minPay - ₹$maxPay' : '₹$minPay';

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? 'Untitled Position',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job['work_mode']?.toString().toUpperCase() ?? ''} • ${job['location'] ?? 'Remote'}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: _isBookmarked ? colorScheme.secondary : null,
                ),
                onPressed: _toggleSave,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.hintColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  (job['working_days'] as List?)?.join(', ') ?? 'N/A',
                  style: textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: theme.hintColor),
              const SizedBox(width: 4),
              Text(
                '${job['shift_start']?.toString().substring(0, 5) ?? ''} - ${job['shift_end']?.toString().substring(0, 5) ?? ''}',
                style: textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salaryStr,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    payType.toString().toUpperCase(),
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: (widget.canApply && !_isApplying) ? _applyJob : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
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
                    : Text(widget.canApply ? "Apply" : "Applied"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
