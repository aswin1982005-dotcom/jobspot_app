import 'package:flutter/material.dart';

class DashboardShell extends StatefulWidget {
  final List<Widget> screens;
  final List<NavigationDestination> destinations;
  final int initialIndex;
  final Function(int)? onTabChanged;

  const DashboardShell({
    super.key,
    required this.screens,
    required this.destinations,
    this.initialIndex = 0,
    this.onTabChanged,
  }) : assert(
         screens.length == destinations.length,
         'Screens and destinations must have the same length',
       );

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late int _selectedIndex;
  late List<bool> _builtScreens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _builtScreens = List.filled(widget.screens.length, false);
    _builtScreens[_selectedIndex] = true; // Mark initial screen as built
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _builtScreens[index] = true; // Lazily build this screen
    });
    widget.onTabChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create the list of children for IndexedStack
    // If a screen hasn't been visited yet, use an empty SizedBox to save resources.
    // Once visited, the actual screen is kept alive by IndexedStack.
    final stackChildren = List<Widget>.generate(widget.screens.length, (index) {
      if (_builtScreens[index]) {
        return widget.screens[index];
      }
      return const SizedBox.shrink();
    });

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: stackChildren),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 70,
        destinations: widget.destinations,
      ),
    );
  }
}
