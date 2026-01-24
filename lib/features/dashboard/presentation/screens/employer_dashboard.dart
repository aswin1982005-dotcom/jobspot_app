import 'package:flutter/material.dart';
import 'package:jobspot_app/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/employer/employer_home_tab.dart';
import 'package:jobspot_app/features/applications/applicants_tab.dart';
import 'package:jobspot_app/features/jobs/presentation/job_posting_tab.dart';
import 'package:jobspot_app/features/profile/presentation/profile_tab.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/employer_home_provider.dart';
import 'package:jobspot_app/core/utils/profile_completion_manager.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  @override
  void initState() {
    super.initState();
    ProfileCompletionManager.checkAndPrompt(context, 'employer');
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      screens: [
        ChangeNotifierProvider(
          create: (_) => EmployerHomeProvider()..loadData(),
          child: const EmployerHomeTab(),
        ),
        // Pass empty lists initially, they will fetch their own data or can be refactored later
        // For now, these tabs manage their own state which is fine.
        const JobPostingTab(),
        const ApplicantsTab(),
        const ProfileTab(role: 'employer'),
      ],
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article),
          label: 'Job Postings',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt),
          label: 'Applicants',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
