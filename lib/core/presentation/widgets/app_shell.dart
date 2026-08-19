import 'package:flutter/material.dart';

import '../../theme/app_breakpoints.dart';

class AppNavDestination {
  final IconData icon;
  final String label;

  const AppNavDestination({required this.icon, required this.label});
}

/// Shared app shell: header + body + primary navigation. Responsive per
/// design.md — a bottom [NavigationBar] below [AppBreakpoints.wide]
/// (Android touch-first), a persistent [NavigationRail] at or above it
/// (Windows keyboard/scanner-first, more working area retained for the
/// body).
///
/// [destinations] must have 0 (no navigation) or at least 2 entries —
/// [NavigationBar] asserts on a single destination.
class AppShell extends StatelessWidget {
  final String title;
  final Widget body;
  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<Widget> actions;

  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    if (destinations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: body,
      );
    }

    if (isWide) {
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(growable: false),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map(
              (d) => NavigationDestination(icon: Icon(d.icon), label: d.label),
            )
            .toList(growable: false),
      ),
    );
  }
}
