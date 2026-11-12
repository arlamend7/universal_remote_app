import 'package:flutter/material.dart';

import '../../views/session/session_countdown.dart';
import '../../views/session/session_prompt_coordinator.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.index,
    required this.onSelect,
    required this.pages,
    this.session,
  });
  final int index;
  final ValueChanged<int> onSelect;
  final List<Widget> pages;
  final SessionPromptCoordinator? session;
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
      child: _destinations(),
    ),
  );
  Widget _destinations() {
    final prompts = session;
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (destination) {
        if (destination == pages.length) {
          prompts?.open();
          return;
        }
        onSelect(destination);
      },
      destinations: [
        const NavigationDestination(
          label: 'Remote',
          icon: Icon(Icons.settings_remote_outlined),
          selectedIcon: Icon(Icons.settings_remote),
        ),
        const NavigationDestination(
          label: 'Devices',
          icon: Icon(Icons.tv_outlined),
          selectedIcon: Icon(Icons.tv),
        ),
        const NavigationDestination(
          label: 'Settings',
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune),
        ),
        if (prompts != null)
          SessionCountdown(
            session: prompts.session,
            visible: prompts.shellVisible,
            builder: _sessionDestination,
          ),
      ],
    );
  }

  Widget _sessionDestination(BuildContext context, String time) =>
      NavigationDestination(
        tooltip: 'Ad options',
        label: time == '00:00' ? 'Ads' : time,
        icon: const Icon(Icons.ondemand_video_outlined),
      );
}
