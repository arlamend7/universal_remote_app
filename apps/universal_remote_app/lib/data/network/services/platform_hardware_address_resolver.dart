import 'package:remote_core/remote_core.dart';

import 'dart:io';

import '../functions/parse_neighbor_address.dart';
import 'neighbor_command_runner.dart';

/// Mobile platforms retain manual entry; restricted neighbor tables are not bypassed.
final class PlatformHardwareAddressResolver implements HardwareAddressResolver {
  PlatformHardwareAddressResolver({
    Future<String?> Function(String)? lookup,
    bool? supported,
  }) : lookup = lookup ?? NeighborCommandRunner().read,
       supported = supported ?? Platform.isMacOS;
  final Future<String?> Function(String) lookup;
  final bool supported;
  @override
  Future<String?> resolve(InternetAddress address) async {
    if (!supported ||
        address.type != InternetAddressType.IPv4 ||
        address.isLoopback ||
        address.isMulticast ||
        address.rawAddress.first == 0 ||
        address.rawAddress.first >= 240) {
      return null;
    }
    try {
      final text = await lookup(address.address)
          .timeout(const Duration(seconds: 2));
      return text == null ? null : parseNeighborAddress(text, address.address);
    } catch (_) {
      return null;
    }
  }
}
