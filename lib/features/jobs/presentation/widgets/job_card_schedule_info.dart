import 'package:flutter/material.dart';

class JobCardScheduleInfo extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobCardScheduleInfo({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final hintColor = theme.hintColor;

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 16, color: hintColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            (job['working_days'] as List?)?.join(', ') ?? 'N/A',
            style: textTheme.bodySmall?.copyWith(color: hintColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.access_time, size: 16, color: hintColor),
        const SizedBox(width: 4),
        Text(
          '${job['shift_start']?.toString().substring(0, 5) ?? ''} - ${job['shift_end']?.toString().substring(0, 5) ?? ''}',
          style: textTheme.bodySmall?.copyWith(color: hintColor),
        ),
      ],
    );
  }
}
