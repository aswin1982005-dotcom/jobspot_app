import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: provider.notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return ListTile(
                tileColor: notification.isRead
                    ? null
                    : Theme.of(context).primaryColor.withValues(alpha: 0.05),
                leading: CircleAvatar(
                  backgroundColor: _getIconColor(
                    notification.type,
                  ).withValues(alpha: 0.1),
                  child: Icon(
                    _getIcon(notification.type),
                    color: _getIconColor(notification.type),
                    size: 20,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notification.body),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                onTap: () {
                  if (!notification.isRead) {
                    provider.markAsRead(notification.id);
                  }
                  _handleNavigation(context, notification);
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'job_post':
        return Icons.work_outline;
      case 'application_status':
        return Icons.assignment_ind_outlined;
      case 'new_applicant':
        return Icons.person_add_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'job_post':
        return Colors.blue;
      case 'application_status':
        return Colors.green;
      case 'new_applicant':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _handleNavigation(BuildContext context, dynamic notification) {
    // TODO: Implement navigation based on notification.type and notification.relatedId
    // e.g. Navigate to JobDetailsScreen, ApplicationStatusScreen, etc.
  }
}
