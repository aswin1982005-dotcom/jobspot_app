import 'package:flutter/material.dart';
import 'package:jobspot_app/features/seeker_dashboard/presentation/tabs/home_tab.dart';
import 'package:jobspot_app/features/seeker_dashboard/presentation/tabs/search_tab.dart';
import 'package:jobspot_app/features/seeker_dashboard/presentation/tabs/map_tab.dart';
import 'package:jobspot_app/features/profile/presentation/profile_tab.dart';

class SeekerDashboardScreen extends StatefulWidget {
  const SeekerDashboardScreen({super.key});

  @override
  State<SeekerDashboardScreen> createState() => _SeekerDashboardScreenState();
}

class _SeekerDashboardScreenState extends State<SeekerDashboardScreen> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We recreate the screens list inside build so that when _selectedIndex changes, 
    // the specific screen is reconstructed, triggering its initState/data fetching.
    // Using a Key for each tab also ensures they are treated as fresh widgets.
    final List<Widget> screens = [
      HomeTab(key: _selectedIndex == 0 ? UniqueKey() : null),
      SearchTab(key: _selectedIndex == 1 ? UniqueKey() : null),
      MapTab(key: _selectedIndex == 2 ? UniqueKey() : null),
      ProfileTab(key: _selectedIndex == 3 ? UniqueKey() : null, role: 'seeker'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 70,
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
      ),
    );
  }
}
