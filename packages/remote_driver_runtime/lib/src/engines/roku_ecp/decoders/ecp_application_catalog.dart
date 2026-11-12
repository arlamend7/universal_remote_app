import 'package:remote_core/remote_core.dart';
import 'package:xml/xml.dart';

/// Apps and inputs reported by `query/apps`. Which app IDs are inputs, and
/// the keys that select them, come from integration data.
final class EcpApplicationCatalog {
  EcpApplicationCatalog(XmlElement root, Uri endpoint, this.inputKeys)
    : apps = [
        for (final app in root.findElements('app'))
          if (RegExp(r'^[0-9]+$').hasMatch(app.getAttribute('id') ?? '') &&
              app.innerText.trim().isNotEmpty)
            DeviceApplication(
              app.getAttribute('id')!,
              app.innerText.trim(),
              artwork: endpoint.replace(
                pathSegments: ['query', 'icon', app.getAttribute('id')!],
              ),
            ),
      ],
      inputs = [
        for (final app in root.findElements('app'))
          if (inputKeys.containsKey(app.getAttribute('id')))
            DeviceInput(app.getAttribute('id')!, app.innerText.trim()),
      ];

  final List<DeviceApplication> apps;
  final List<DeviceInput> inputs;

  /// Input app ID → ECP key that selects it.
  final Map<String, String> inputKeys;

  String? keyForInput(String id) =>
      inputs.any((input) => input.id == id) ? inputKeys[id] : null;
}
