import 'package:flutter/material.dart';
import 'package:jobspot_app/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:jobspot_app/features/profile/presentation/profile_tab.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/seeker/home_tab.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/seeker/map_tab.dart';
import 'package:jobspot_app/features/dashboard/presentation/tabs/seeker/search_tab.dart';

class SeekerDashboard extends StatefulWidget {
  const SeekerDashboard({super.key});

  @override
  State<SeekerDashboard> createState() => _SeekerDashboardState();
}

class _SeekerDashboardState extends State<SeekerDashboard> {
  // Using UniqueKey to force refresh when switching back if needed,
  // or keys can be managed by the shell if we move state up.
  // For now, keeping the simple list creation.

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      screens: const [
        HomeTab(),
        SearchTab(),
        MapTab(),
        ProfileTab(role: 'seeker'),
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
