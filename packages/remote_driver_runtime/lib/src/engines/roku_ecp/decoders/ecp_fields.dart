import 'package:remote_core/remote_core.dart';
import 'package:xml/xml.dart';

/// The trimmed text of a child element, or null when absent or empty.
String? rokuField(XmlElement? node, String name) {
  final value = node?.getElement(name)?.innerText.trim();
  return value == null || value.isEmpty ? null : value;
}

List<DeviceChannel> rokuChannels(XmlElement root) {
  if (root.name.local != 'tv-channels') {
    return const [];
  }
  return [
    for (final entry in root.findElements('channel').take(512))
      if (rokuField(entry, 'user-hidden') != 'true')
        if (rokuField(entry, 'number') case final number?)
          DeviceChannel(number, rokuField(entry, 'name') ?? number, number),
  ];
}

Duration? rokuMediaTime(XmlElement root, String field) {
  final raw = rokuField(root, field);
  final milliseconds = raw == null
      ? null
      : RegExp(r'^(\d+)\s*ms$').firstMatch(raw)?.group(1);
  final value = milliseconds == null ? null : int.tryParse(milliseconds);
  return value == null ? null : Duration(milliseconds: value);
}
