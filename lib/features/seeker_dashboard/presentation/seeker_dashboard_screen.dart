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
  Key _refreshKey = UniqueKey();

  Future<void> _handleRefresh() async {
    // Simulate a network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _refreshKey = UniqueKey();
      });
    }
  }

  final List<Widget> _screens = [
    const HomeTab(),
    const SearchTab(),
    const MapTab(),
    const ProfileTab(role: 'seeker'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        displacement: 20,
        color: Theme.of(context).colorScheme.primary,
        child: KeyedSubtree(
          key: _refreshKey,
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
