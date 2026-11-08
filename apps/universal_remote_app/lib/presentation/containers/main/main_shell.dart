import 'package:flutter/material.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.index,
    required this.onSelect,
    required this.pages,
  });
  final int index;
  final ValueChanged<int> onSelect;
  final List<Widget> pages;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(index: index, children: pages),
    ),
    bottomNavigationBar: _bar(),
  );
  Widget _bar() => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: _navigation(),
    ),
  );
  Widget _navigation() => NavigationBar(
    selectedIndex: index,
    onDestinationSelected: onSelect,
    destinations: const [
      NavigationDestination(
        label: 'Remote',
        icon: Icon(Icons.settings_remote_outlined),
        selectedIcon: Icon(Icons.settings_remote),
      ),
      NavigationDestination(
        label: 'Devices',
        icon: Icon(Icons.tv_outlined),
        selectedIcon: Icon(Icons.tv),
      ),
      NavigationDestination(
        label: 'Settings',
        icon: Icon(Icons.tune_outlined),
        selectedIcon: Icon(Icons.tune),
      ),
    ],
  );
}
