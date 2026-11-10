import 'package:remote_core/remote_core.dart';
import 'package:xml/xml.dart';

final class RokuAppCatalog {
  RokuAppCatalog(XmlElement root, Uri endpoint)
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
          if (_inputKeys.containsKey(app.getAttribute('id')))
            DeviceInput(app.getAttribute('id')!, app.innerText.trim()),
      ];

  final List<DeviceApplication> apps;
  final List<DeviceInput> inputs;

  static const _inputKeys = {
    'tvinput.dtv': 'InputTuner',
    'tvinput.hdmi1': 'InputHDMI1',
    'tvinput.hdmi2': 'InputHDMI2',
    'tvinput.hdmi3': 'InputHDMI3',
    'tvinput.hdmi4': 'InputHDMI4',
    'tvinput.cvbs': 'InputAV1',
  };

  String? keyForInput(String id) =>
      inputs.any((input) => input.id == id) ? _inputKeys[id] : null;
}
