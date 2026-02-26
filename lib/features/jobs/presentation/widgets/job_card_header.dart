import 'package:flutter/material.dart';

class JobCardHeader extends StatelessWidget {
  final Map<String, dynamic> job;
  final double iconSize;
  final Widget? trailing;

  const JobCardHeader({
    super.key,
    required this.job,
    this.iconSize = 24,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Row(
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
            size: iconSize,
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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      job['company_name'] ??
                          job['employer_profiles']?['company_name'] ??
                          job['employer']?['company_name'] ??
                          'Company Name',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (job['employer_profiles']?['is_verified'] == true ||
                      job['employer']?['is_verified'] == true) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${job['work_mode']?.toString().toUpperCase() ?? ''} • ${job['location'] ?? 'Remote'}',
                style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
