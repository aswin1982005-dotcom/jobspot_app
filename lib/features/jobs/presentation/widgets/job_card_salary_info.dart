import 'package:flutter/material.dart';

class JobCardSalaryInfo extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobCardSalaryInfo({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final hintColor = theme.hintColor;

    final minPay = job['pay_amount_min'] ?? 0;
    final maxPay = job['pay_amount_max'];
    final payType = job['pay_type']?.toString().toUpperCase() ?? '';
    final salaryStr = maxPay != null ? '₹$minPay - ₹$maxPay' : '₹$minPay';

    return Column(
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
          payType.replaceAll('_', ' '),
          style: textTheme.bodySmall?.copyWith(
            color: hintColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
