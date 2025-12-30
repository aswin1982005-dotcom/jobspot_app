import 'package:flutter/material.dart';
import 'package:jobspot_app/features/jobs/presentation/job_details_screen.dart';

/// A card widget used by employers to view a summary of their job posting.
///
/// Displays key details like title, salary, and status. Tapping the card
/// navigates to the detailed view.
class EmployerJobCard extends StatelessWidget {
  /// The job data to display.
  final Map<String, dynamic> job;

  /// Callback when the edit button is pressed.
  final VoidCallback onEdit;

  /// Callback when the close/reopen button is pressed.
  final VoidCallback onClose;

  const EmployerJobCard({
    super.key,
    required this.job,
    required this.onEdit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final hintColor = theme.hintColor;

    final isActive = job['is_active'] ?? true;
    final payType = job['pay_type']?.toString().toUpperCase() ?? '';
    final minPay = job['pay_amount_min'] ?? 0;
    final maxPay = job['pay_amount_max'];
    final salaryStr = maxPay != null ? '₹$minPay - ₹$maxPay' : '₹$minPay';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                JobDetailsScreen(job: job, userRole: 'employer'),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
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
                        style: textTheme.bodyMedium?.copyWith(color: hintColor),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isActive),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salaryStr,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      payType.replaceAll('_', ' '),
                      style: textTheme.bodySmall?.copyWith(color: hintColor),
                    ),
                  ],
                ),
                if (job['same_day_pay'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 14,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SAME DAY PAY',
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
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
                    onPressed: isActive ? onClose : null,
                    icon: Icon(
                      isActive ? Icons.lock_outline : Icons.lock,
                      size: 18,
                    ),
                    label: Text(isActive ? 'Close' : 'Reopen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? colorScheme.error
                          : colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
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
}
