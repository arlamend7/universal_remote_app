import 'dart:io';

import 'package:remote_core/remote_core.dart';

/// Which network addresses an integration accepts for a device.
enum AddressPolicy {
  /// Any numeric unicast address (not loopback, multicast or broadcast).
  numeric('numeric'),

  /// Private IPv4/IPv6 unique-local addresses only.
  local('local'),

  /// Private IPv4 addresses only.
  localIpv4('local-ipv4');

  const AddressPolicy(this.id);
  final String id;

  static AddressPolicy parse(Object? value) {
    final policy = values.where((candidate) => candidate.id == value);
    if (policy.isEmpty) {
      throw const FormatException('Unknown address policy.');
    }
    return policy.single;
  }

  bool accepts(String host) {
    final address = InternetAddress.tryParse(host.trim());
    if (address == null) {
      return false;
    }
    return switch (this) {
      AddressPolicy.numeric => _unicast(address),
      AddressPolicy.local => isLocalProbeAddress(address.address),
      AddressPolicy.localIpv4 =>
        address.type == InternetAddressType.IPv4 &&
            isLocalProbeAddress(address.address),
    };
  }

  static bool _unicast(InternetAddress address) =>
      !address.isMulticast &&
      !address.isLoopback &&
      !{'0.0.0.0', '::', '255.255.255.255'}.contains(address.address);
}
