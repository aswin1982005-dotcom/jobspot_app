import 'package:flutter/material.dart';
import 'package:jobspot_app/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:jobspot_app/features/profile/presentation/profile_tab.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/seeker/home_tab.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/seeker/map_tab.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/seeker/search_tab.dart';
import 'package:provider/provider.dart';
import 'package:jobspot_app/features/dashboard/presentation/providers/seeker_home_provider.dart';
import 'package:jobspot_app/core/utils/profile_completion_manager.dart';

class SeekerDashboard extends StatefulWidget {
  const SeekerDashboard({super.key});

  @override
  State<SeekerDashboard> createState() => _SeekerDashboardState();
}

class _SeekerDashboardState extends State<SeekerDashboard> {
  @override
  void initState() {
    super.initState();
    ProfileCompletionManager.checkAndPrompt(context, 'seeker');
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      screens: [
        ChangeNotifierProvider(
          create: (_) => SeekerHomeProvider()..loadData(),
          child: const HomeTab(),
        ),
        const SearchTab(),
        const MapTab(),
        const ProfileTab(role: 'seeker'),
      ],
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.pin_drop_outlined),
          selectedIcon: Icon(Icons.pin_drop_rounded),
          label: 'Job Map',
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
