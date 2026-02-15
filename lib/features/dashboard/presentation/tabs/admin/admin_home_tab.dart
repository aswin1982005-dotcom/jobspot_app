import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/admin_home_provider.dart';
import 'package:jobspot_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:jobspot_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:provider/provider.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 7).floor()} weeks ago';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Consumer<AdminHomeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard 🛡️',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Platform management overview',
                        style: textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Consumer<NotificationProvider>(
                        builder: (context, notifProvider, child) {
                          return Badge(
                            label: notifProvider.unreadCount > 0
                                ? Text('${notifProvider.unreadCount}')
                                : null,
                            isLabelVisible: notifProvider.unreadCount > 0,
                            child: Icon(
                              Icons.notifications_outlined,
                              color: theme.iconTheme.color,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Platform Statistics Dashboard
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8F6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top row: Users and Jobs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Total Users',
                          provider.totalUsers,
                          Icons.people_rounded,
                          Colors.white,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          'Total Jobs',
                          provider.totalJobs,
                          Icons.work_rounded,
                          Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.2),
                      thickness: 1,
                    ),
                    const SizedBox(height: 16),
                    // Bottom row: Pending reports
                    _buildStatItem(
                      'Pending Reports',
                      provider.totalPendingReports,
                      Icons.flag_rounded,
                      Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      context,
                      'Active Jobs',
                      provider.activeJobs.toString(),
                      Icons.work_outline,
                      AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStatCard(
                      context,
                      'Reported Jobs',
                      provider.reportedJobs.toString(),
                      Icons.report_outlined,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      context,
                      'Disabled Users',
                      provider.disabledUsers.toString(),
                      Icons.block_outlined,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStatCard(
                      context,
                      'New Signups',
                      provider.recentSignups.toString(),
                      Icons.person_add_outlined,
                      AppColors.sky,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Users Section
              if (provider.recentUsers.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Signups',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...provider.recentUsers.map((user) {
                  final role = user['role'] ?? '';
                  final seeker = user['seekers'] as List?;
                  final employer = user['employers'] as List?;

                  String name = 'Unknown User';
                  String? avatarUrl;

                  if (role == 'seeker' && seeker != null && seeker.isNotEmpty) {
                    final seekerData = seeker[0] as Map<String, dynamic>?;
                    name = seekerData?['full_name'] ?? 'Job Seeker';
                    avatarUrl = seekerData?['avatar_url'];
                  } else if (role == 'employer' &&
                      employer != null &&
                      employer.isNotEmpty) {
                    final employerData = employer[0] as Map<String, dynamic>?;
                    name = employerData?['company_name'] ?? 'Company';
                    avatarUrl = employerData?['logo_url'];
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Icon(
                                  role == 'employer'
                                      ? Icons.business
                                      : Icons.person,
                                )
                              : null,
                        ),
                        title: Text(name),
                        subtitle: Text(
                          '${role[0].toUpperCase()}${role.substring(1)} • ${_formatDate(user['created_at'])}',
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Recent Jobs Section
              if (provider.recentJobs.isNotEmpty) ...[
                Text(
                  'Recent Job Posts',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...provider.recentJobs.map((job) {
                  final isActive = job['is_active'] ?? false;
                  final isDisabled = job['admin_disabled'] ?? false;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? Colors.red.withValues(alpha: 0.1)
                                : isActive
                                ? AppColors.teal.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isDisabled
                                ? Icons.block
                                : isActive
                                ? Icons.check_circle
                                : Icons.archive,
                            color: isDisabled
                                ? Colors.red
                                : isActive
                                ? AppColors.teal
                                : Colors.grey,
                          ),
                        ),
                        title: Text(
                          job['title'] ?? 'Job Title',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${job['company'] ?? 'Company'} • ${job['city']}, ${job['state']}\n${_formatDate(job['created_at'])}',
                        ),
                        isThreeLine: true,
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
