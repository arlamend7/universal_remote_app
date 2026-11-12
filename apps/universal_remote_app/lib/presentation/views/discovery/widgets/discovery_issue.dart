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
      actions: _actions(context),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final offline = type == ConnectionIssueType.internetUnavailable;
    final permission = type == ConnectionIssueType.localNetworkPermissionDenied;
    return [
      if (!permission)
        FilledButton.tonal(onPressed: retry, child: Text('Try again')),
      if (!offline && (Platform.isIOS || Platform.isAndroid))
        OutlinedButton(
          onPressed: openDiscoverySettings,
          child: Text('Open Settings'),
        ),
      if (offline || permission)
        TextButton(
          onPressed: dismiss,
          child: Text(offline ? 'Continue offline' : 'Not now'),
        ),
    ];
  }
}
