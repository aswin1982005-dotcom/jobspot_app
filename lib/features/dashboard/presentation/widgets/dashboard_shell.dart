import 'package:flutter/material.dart';

class DashboardShell extends StatefulWidget {
  final List<Widget> screens;
  final List<NavigationDestination> destinations;
  final int initialIndex;

  const DashboardShell({
    super.key,
    required this.screens,
    required this.destinations,
    this.initialIndex = 0,
  }) : assert(
         screens.length == destinations.length,
         'Screens and destinations must have the same length',
       );

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: widget.screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 70,
        // Consistent height
        destinations: widget.destinations,
      ),
    );
  }
}
