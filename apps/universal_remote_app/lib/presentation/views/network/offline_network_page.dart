import 'dart:io';

import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../data/network/services/open_discovery_settings.dart';

class OfflineNetworkPage extends StatelessWidget {
  const OfflineNetworkPage({
    super.key,
    required this.onRetry,
    required this.onContinueOffline,
  });

  final VoidCallback onRetry;
  final VoidCallback onContinueOffline;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: LayoutBuilder(builder: _layout),
          ),
        ),
      ),
    ),
  );

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final content = _content(context);
    final actions = _actions(context);
    if (constraints.maxHeight < 480 ||
        MediaQuery.textScalerOf(context).scale(16) > 24) {
      return SingleChildScrollView(
        child: Column(spacing: 24, children: [content, actions]),
      );
    }
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (_, bodyConstraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: bodyConstraints.maxHeight,
                ),
                child: content,
              ),
            ),
          ),
        ),
        actions,
      ],
    );
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      spacing: 22,
      children: [
        Text(
          'NETWORK CONNECTION',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        _illustration(theme.colorScheme),
        _message(theme),
      ],
    );
  }

  Widget _illustration(ColorScheme colors) => ExcludeSemantics(
    child: Container(
      width: 190,
      height: 190,
      padding: const EdgeInsets.all(28),
      decoration: _circle(colors.surfaceContainerLow, colors.outlineVariant),
      child: DecoratedBox(
        decoration: _circle(colors.surfaceContainerHigh, colors.outlineVariant),
        child: Icon(Icons.wifi_off_rounded, color: colors.primary, size: 48),
      ),
    ),
  );

  BoxDecoration _circle(Color fill, Color border) => BoxDecoration(
    color: fill,
    shape: BoxShape.circle,
    border: Border.all(color: border),
  );

  Widget _message(ThemeData theme) => Column(
    spacing: 12,
    children: [
      Chip(
        avatar: Icon(Icons.circle, size: 9, color: theme.colorScheme.error),
        label: const Text('Wi-Fi disconnected'),
        shape: const StadiumBorder(),
      ),
      Semantics(
        header: true,
        child: Text(
          'No local network',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Text(
        'Connect to the same Wi-Fi network as your TV.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _actions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      AppSheetActions(
        secondary: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
        primary: FilledButton.icon(
          onPressed: Platform.isAndroid
              ? openDiscoverySettings
              : () => _showWifiHelp(context),
          icon: const Icon(Icons.wifi),
          label: Text(Platform.isAndroid ? 'Wi-Fi settings' : 'Wi-Fi help'),
        ),
      ),
      OutlinedButton(
        onPressed: onContinueOffline,
        child: const Text('Continue offline'),
      ),
      Center(
        child: TextButton(
          onPressed: () => _showDetails(context),
          child: const Text('Connection details'),
        ),
      ),
    ],
  );

  Future<void> _showWifiHelp(BuildContext context) => showAppSheet<void>(
    context,
    title: 'Turn on Wi-Fi',
    child: Text(
      Platform.isMacOS
          ? 'Open System Settings → Wi-Fi and join your TV’s network.'
          : 'Open Settings → Wi-Fi and join your TV’s network.',
    ),
  );

  Future<void> _showDetails(BuildContext context) => showAppSheet<void>(
    context,
    title: 'Connection details',
    child: const Text(
      'Your device has no Wi-Fi or Ethernet connection. Universal Remote communicates with TVs on your local network. A wired connection works too.',
    ),
  );
}
