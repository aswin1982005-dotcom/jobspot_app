import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/data/services/admin_service.dart';

class AdminActivityLogScreen extends StatefulWidget {
  final String? filterUserId;

  const AdminActivityLogScreen({super.key, this.filterUserId});

  @override
  State<AdminActivityLogScreen> createState() => _AdminActivityLogScreenState();
}

class _AdminActivityLogScreenState extends State<AdminActivityLogScreen> {
  final AdminService _adminService = AdminService();
  final List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _adminService.fetchAdminActions(limit: 100);

      // Filter locally if a specific user is requested,
      // since the RPC might not support filtering by target_id currently.
      if (widget.filterUserId != null) {
        _logs.assignAll(
          logs.where((log) => log['target_id'] == widget.filterUserId).toList(),
        );
      } else {
        _logs.assignAll(logs);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filterUserId != null
              ? 'User Activity Log'
              : 'Admin Activity Log',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text(
                    'No activity logs found',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLogs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final actionType = log['action_type'] ?? 'Unknown Action';
                  final targetType = log['target_type'] ?? '';
                  final reason = log['reason'];

                  IconData icon = Icons.info;
                  Color color = AppColors.teal;

                  if (actionType.contains('disable') ||
                      actionType.contains('unverify')) {
                    color = Colors.red;
                    icon = Icons.block;
                  } else if (actionType.contains('verify') ||
                      actionType.contains('enable')) {
                    color = Colors.green;
                    icon = Icons.check_circle;
                  } else if (actionType.contains('report')) {
                    color = Colors.orange;
                    icon = Icons.flag;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: color, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  actionType.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDate(log['created_at']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Target: ${targetType.toUpperCase()} (${log['target_id']})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (reason != null &&
                              reason.toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: $reason',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

extension on List<Map<String, dynamic>> {
  void assignAll(List<Map<String, dynamic>> values) {
    clear();
    addAll(values);
  }
}
