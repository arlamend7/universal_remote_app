import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../data/network/services/open_discovery_settings.dart';
import '../../../../domains/discovery/models/connection_issue_type.dart';
import '../../../shared/localization/journey_text.dart';
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
        journeyText(context, 'No network route', 'Sem conexão de rede'),
        journeyText(
          context,
          'Connect to a local network and try again.',
          'Conecte-se a uma rede local e tente novamente.',
        ),
        Icons.wifi_off,
      ),
      ConnectionIssueType.internetUnavailable => (
        journeyText(
          context,
          'Driver catalog unreachable',
          'Catálogo de drivers inacessível',
        ),
        journeyText(
          context,
          'You can continue on your local network with installed drivers.',
          'Você pode continuar na rede local com os drivers instalados.',
        ),
        Icons.cloud_off_outlined,
      ),
      ConnectionIssueType.localNetworkPermissionDenied => (
        journeyText(
          context,
          'Local network permission needed',
          'Permissão de rede necessária',
        ),
        journeyText(
          context,
          'Allow Local Network access in Settings to find nearby devices.',
          'Permita o acesso à rede local nos Ajustes para encontrar dispositivos próximos.',
        ),
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
        FilledButton.tonal(
          onPressed: retry,
          child: Text(journeyText(context, 'Try again', 'Tentar novamente')),
        ),
      if (!offline && (Platform.isIOS || Platform.isAndroid))
        OutlinedButton(
          onPressed: openDiscoverySettings,
          child: Text(journeyText(context, 'Open Settings', 'Abrir ajustes')),
        ),
      if (offline || permission)
        TextButton(
          onPressed: dismiss,
          child: Text(
            offline
                ? journeyText(context, 'Continue offline', 'Continuar offline')
                : journeyText(context, 'Not now', 'Agora não'),
          ),
        ),
    ];
  }
}
