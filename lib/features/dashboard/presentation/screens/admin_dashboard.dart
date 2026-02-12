import 'package:flutter/material.dart';
import 'package:jobspot_app/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/admin/admin_home_tab.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/admin/user_management_tab.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/admin/job_management_tab.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/admin/support_tab.dart';
import 'package:jobspot_app/features/profile/presentation/profile_tab.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/admin_home_provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/user_management_provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/job_management_provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/support_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminHomeProvider()..loadData()),
        ChangeNotifierProvider(
          create: (_) => UserManagementProvider()..loadUsers(),
        ),
        ChangeNotifierProvider(
          create: (_) => JobManagementProvider()..loadJobs(),
        ),
        ChangeNotifierProvider(create: (_) => SupportProvider()..loadReports()),
      ],
      child: DashboardShell(
        screens: const [
          AdminHomeTab(),
          UserManagementTab(),
          JobManagementTab(),
          SupportTab(),
          ProfileTab(role: 'admin'),
        ],
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Support',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
