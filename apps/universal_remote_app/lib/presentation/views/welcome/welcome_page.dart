import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../settings/viewmodels/settings_viewmodel.dart';
import '../settings/widgets/appearance_settings.dart';
import 'widgets/welcome_intro.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.dependencies,
    required this.onContinue,
  });

  final AppDependencies dependencies;
  final ValueChanged<BuildContext> onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _layout(context),
          ),
        ),
      ),
    ),
  );

  Widget _layout(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxHeight < 480 ||
          MediaQuery.textScalerOf(context).scale(16) > 24) {
        return SingleChildScrollView(
          child: Column(
            spacing: 24,
            children: [_introAndAppearance(context), _actions(context)],
          ),
        );
      }
      return Column(
        children: [
          Expanded(child: _scrollingContent(context)),
          _actions(context),
        ],
      );
    },
  );

  Widget _scrollingContent(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: _introAndAppearance(context),
      ),
    ),
  );

  Widget _introAndAppearance(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 28,
      children: [
        const WelcomeIntro(),
        AppearanceSettings(
          model: SettingsViewModel(dependencies),
          header: _appearanceHeading(context),
          footer: _localNetworkNote(context),
        ),
      ],
    ),
  );

  Widget _appearanceHeading(BuildContext context) => Row(
    spacing: 8,
    children: [
      const Icon(Icons.light_mode_outlined, size: 20),
      Expanded(
        child: Text(
          'Personalize appearance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ],
  );

  Widget _localNetworkNote(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        spacing: 8,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 17,
            color: theme.colorScheme.primary,
          ),
          Expanded(
            child: Text(
              'TV commands stay on your local network.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => onContinue(context),
          icon: const Icon(Icons.search),
          label: const Text('Find Nearby TVs'),
        ),
      ],
    ),
  );
}
