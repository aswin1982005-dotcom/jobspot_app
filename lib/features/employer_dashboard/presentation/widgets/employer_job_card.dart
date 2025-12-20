import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';

class EmployerJobCard extends StatelessWidget {
  final String company;
  final String position;
  final String location;
  final String salary;
  final String type;
  final IconData logo;
  final Color logoColor;
  final String status; // "open" or "closed"
  final VoidCallback onEdit;
  final VoidCallback onClose;

  const EmployerJobCard({
    super.key,
    required this.company,
    required this.position,
    required this.location,
    required this.salary,
    required this.type,
    required this.logo,
    required this.logoColor,
    required this.status,
    required this.onEdit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme
        .of(context)
        .textTheme;
    final isOpen = status.toLowerCase() == 'open';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
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
                  color: logoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(logo, color: logoColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(position, style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$company • $location',
                        style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.withValues(alpha: 0.1) : Colors
                      .red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isOpen ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(salary, style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(type, style: textTheme.bodySmall),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: ActionChip(
                  onPressed: onEdit,
                  label: const Center(child: Text('Edit')),
                  avatar: const Icon(Icons.edit, size: 16),
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionChip(
                  onPressed: isOpen ? onClose : null,
                  label: Center(child: Text(isOpen ? 'Close' : 'Closed')),
                  avatar: Icon(
                      isOpen ? Icons.lock_outline : Icons.lock, size: 16),
                  backgroundColor: isOpen ? AppColors.white : Colors.grey[100],
                  disabledColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                        color: isOpen ? Colors.grey.shade300 : Colors
                            .transparent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
