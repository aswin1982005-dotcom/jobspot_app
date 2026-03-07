import 'package:flutter/material.dart';
import 'package:jobspot_app/core/theme/app_theme.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/user_management_provider.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/seeker_profile_view.dart';
import 'package:jobspot_app/features/profile/presentation/widgets/employer_profile_view.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/admin/widgets/message_user_dialog.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/admin/admin_activity_log_screen.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'Newest Joined';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  void _openSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort Users', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Newest Joined'),
                trailing: _sortOption == 'Newest Joined'
                    ? const Icon(Icons.check, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => _sortOption = 'Newest Joined');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Oldest Joined'),
                trailing: _sortOption == 'Oldest Joined'
                    ? const Icon(Icons.check, color: AppColors.purple)
                    : null,
                onTap: () {
                  setState(() => _sortOption = 'Oldest Joined');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Consumer<UserManagementProvider>(
      builder: (context, provider, _) {
        var filteredUsers = List<Map<String, dynamic>>.from(provider.users);

        // 1. Search filter
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          filteredUsers = filteredUsers.where((user) {
            String name = '';
            String city = '';
            String email = user['email']?.toString().toLowerCase() ?? '';
            final role = user['role'] ?? '';

            if (role == 'seeker' && user['seeker_profile'] != null) {
              name =
                  user['seeker_profile']['full_name']
                      ?.toString()
                      .toLowerCase() ??
                  '';
              city =
                  user['seeker_profile']['city']?.toString().toLowerCase() ??
                  '';
            } else if (role == 'employer' && user['employer_profile'] != null) {
              name =
                  user['employer_profile']['company_name']
                      ?.toString()
                      .toLowerCase() ??
                  '';
              city =
                  user['employer_profile']['city']?.toString().toLowerCase() ??
                  '';
            }

            return name.contains(query) ||
                city.contains(query) ||
                email.contains(query);
          }).toList();
        }

        // 2. Sort
        filteredUsers.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
          if (_sortOption == 'Newest Joined') {
            return dateB.compareTo(dateA);
          } else {
            return dateA.compareTo(dateB);
          }
        });

        return Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterChip(
                          context,
                          'All Users',
                          provider.roleFilter == null,
                          () => provider.setRoleFilter(null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterChip(
                          context,
                          'Seekers',
                          provider.roleFilter == 'seeker',
                          () => provider.setRoleFilter('seeker'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterChip(
                          context,
                          'Employers',
                          provider.roleFilter == 'employer',
                          () => provider.setRoleFilter('employer'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterChip(
                          context,
                          'Active Only',
                          provider.disabledFilter == false,
                          () => provider.setDisabledFilter(false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterChip(
                          context,
                          'Disabled Only',
                          provider.disabledFilter == true,
                          () => provider.setDisabledFilter(true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, or city...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _openSortOptions,
                        icon: const Icon(Icons.sort),
                        tooltip: 'Sort Users',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // User List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: provider.refresh,
                      child: filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: theme.hintColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No users match your search'
                                        : 'No users found',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                return _buildUserCard(context, user, provider);
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.purple
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> user,
    UserManagementProvider provider,
  ) {
    final theme = Theme.of(context);
    final role = user['role'] ?? '';
    final isDisabled = user['is_disabled'] ?? false;
    final userId = user['user_id'] ?? '';

    String name = 'Unknown User';
    String? subtitle;
    String? avatarUrl;

    if (role == 'seeker') {
      final seekerProfile = user['seeker_profile'];
      if (seekerProfile is Map && seekerProfile.isNotEmpty) {
        name = seekerProfile['full_name'] ?? 'Job Seeker';
        subtitle = seekerProfile['city'] as String?;
        avatarUrl = user['avatar_url'] as String?;
      }
    } else if (role == 'employer') {
      final employerProfile = user['employer_profile'];
      if (employerProfile is Map && employerProfile.isNotEmpty) {
        name = employerProfile['company_name'] ?? 'Employer';
        subtitle = employerProfile['city'] as String?;
        avatarUrl = user['avatar_url'] as String?;
      }
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
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Icon(role == 'employer' ? Icons.business : Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (role == 'employer' &&
                              user['employer_profile']?['is_verified'] == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                color: AppColors.purple,
                                size: 16,
                              ),
                            ),
                          if (isDisabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DISABLED',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            role == 'employer'
                                ? Icons.business_center
                                : Icons.person_search,
                            size: 14,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            role.isNotEmpty
                                ? '${role[0].toUpperCase()}${role.substring(1)}'
                                : 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Joined: ${_formatDate(user['created_at'])}',
                        style: TextStyle(fontSize: 11, color: theme.hintColor),
                      ),
                      if (isDisabled && user['disable_reason'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Reason: ${user['disable_reason']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUserActions(context, user, provider),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Actions'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleUserStatus(
                      context,
                      userId,
                      isDisabled,
                      provider,
                    ),
                    icon: Icon(
                      isDisabled ? Icons.check_circle : Icons.block,
                      size: 16,
                    ),
                    label: Text(isDisabled ? 'Enable' : 'Disable'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDisabled ? AppColors.teal : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  void _showUserActions(
    BuildContext context,
    Map<String, dynamic> user,
    UserManagementProvider provider,
  ) {
    String name = 'User';
    final role = user['role'] ?? '';
    if (role == 'seeker' && user['profile_completed'] == true) {
      name = user['seeker_profile']?['full_name'] ?? 'Job Seeker';
    } else if (role == 'employer' && user['profile_completed'] == true) {
      name = user['employer_profile']?['company_name'] ?? 'Company';
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('User Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                final role = user['role'];
                if (role == 'seeker' && user['seeker_profile'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: const Text('Seeker Profile')),
                        body: SeekerProfileView(
                          profileData: user['seeker_profile'],
                          isAdminView: true,
                        ),
                      ),
                    ),
                  );
                } else if (role == 'employer' &&
                    user['employer_profile'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: const Text('Employer Profile')),
                        body: EmployerProfileView(
                          profileData: user['employer_profile'],
                          isAdminView: true,
                        ),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile not available')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => MessageUserDialog(
                    userName: name,
                    onSend: (title, body) async {
                      try {
                        await provider.sendSystemMessage(
                          user['user_id'],
                          title,
                          body,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Message sent successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Activity Log'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminActivityLogScreen(filterUserId: user['user_id']),
                  ),
                );
              },
            ),
            if (user['role'] == 'employer') ...[
              const Divider(),
              ListTile(
                leading: Icon(
                  (user['employer_profile']?['is_verified'] == true)
                      ? Icons.verified
                      : Icons.new_releases,
                  color: (user['employer_profile']?['is_verified'] == true)
                      ? AppColors.purple
                      : null,
                ),
                title: Text(
                  (user['employer_profile']?['is_verified'] == true)
                      ? 'Revoke Verification'
                      : 'Verify Employer',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final isVerified =
                      !(user['employer_profile']?['is_verified'] == true);
                  try {
                    await provider.toggleEmployerVerification(
                      user['user_id'],
                      isVerified,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isVerified
                                ? 'Employer verified'
                                : 'Verification revoked',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleUserStatus(
    BuildContext context,
    String userId,
    bool currentlyDisabled,
    UserManagementProvider provider,
  ) {
    if (currentlyDisabled) {
      // Enable user
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable User'),
          content: const Text('Are you sure you want to enable this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await provider.enableUser(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User enabled')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    } else {
      // Disable user - ask for reason
      final reasonController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for disabling this user:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Reason for disabling',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a reason')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await provider.disableUser(userId, reasonController.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User disabled')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
    }
  }
}
