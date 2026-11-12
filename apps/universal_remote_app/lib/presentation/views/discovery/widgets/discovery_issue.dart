import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../data/network/services/open_discovery_settings.dart';
import '../../../../domains/discovery/models/connection_issue_type.dart';
import '../../../shared/widgets/connection_issue_page.dart';

class DiscoveryIssue extends StatelessWidget {
  const DiscoveryIssue({
    super.key,
    required this.type,
    required this.retry,
    required this.dismiss,
  });

  final ConnectionIssueType type;
  final VoidCallback retry;
  final VoidCallback dismiss;

  @override
  Widget build(BuildContext context) {
    final (title, description, icon) = switch (type) {
      ConnectionIssueType.networkUnavailable => (
        'No network route',
        'Connect to a local network and try again.',
        Icons.wifi_off,
      ),
      ConnectionIssueType.internetUnavailable => (
        'Driver catalog unreachable',
        'You can continue on your local network with installed drivers.',
        Icons.cloud_off_outlined,
      ),
      ConnectionIssueType.localNetworkPermissionDenied => (
        'Local network permission needed',
        'Allow Local Network access in Settings to find nearby devices.',
        Icons.lock_outline,
      ),
    };
    return ConnectionIssuePage(
      title: title,
      description: description,
      icon: icon,
      actions: _actions(),
    );
  }

  List<Widget> _actions() {
    final offline = type == ConnectionIssueType.internetUnavailable;
    final permission = type == ConnectionIssueType.localNetworkPermissionDenied;
    final canOpenSettings = Platform.isIOS || Platform.isAndroid;
    if (permission) {
      return [
        if (canOpenSettings)
          FilledButton(
            onPressed: openDiscoverySettings,
            child: const Text('Open Settings'),
          ),
        OutlinedButton(onPressed: dismiss, child: const Text('Not now')),
      ];
    }
    return [
      FilledButton(onPressed: retry, child: const Text('Try again')),
      if (!offline && canOpenSettings)
        OutlinedButton(
          onPressed: openDiscoverySettings,
          child: const Text('Open Settings'),
        ),
      if (offline)
        OutlinedButton(
          onPressed: dismiss,
          child: const Text('Continue offline'),
        ),
    ];
  }
}
