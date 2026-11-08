import 'package:remote_network/remote_network.dart';

/// Requires the queried host and a LAN interface; never accepts a gateway row.
String? parseNeighborAddress(String output, String host) {
  final pattern = RegExp(
    r'\(' +
        RegExp.escape(host) +
        r'\)\s+at\s+([0-9a-fA-F:]+)\s+on\s+(en[0-9]+|bridge[0-9]+)(?:\s|$)',
    multiLine: true,
  );
  final match = pattern.firstMatch(output);
  if (match == null ||
      RegExp(r'\b(proxy|published)\b', caseSensitive: false).hasMatch(output)) {
    return null;
  }
  return normalizeMacAddress(match.group(1));
}
