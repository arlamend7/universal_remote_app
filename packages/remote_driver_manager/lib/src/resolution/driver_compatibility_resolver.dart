import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'driver_candidate.dart';
import 'driver_match.dart';
import 'compare_device_version.dart';

/// The platform comparator returns null when a version cannot be compared.
typedef DeviceVersionComparator = int? Function(String left, String right);

final class DriverCompatibilityResolver {
  DriverCompatibilityResolver({
    Map<String, DeviceVersionComparator> osVersions = const {
      'Roku OS': compareThreePartDeviceVersion,
    },
    Map<String, DeviceVersionComparator> firmwareVersions = const {
      'webOS': compareThreePartDeviceVersion,
    },
  }) : _osVersions = Map.unmodifiable(osVersions),
       _firmwareVersions = Map.unmodifiable(firmwareVersions);

  final Map<String, DeviceVersionComparator> _osVersions, _firmwareVersions;

  DriverMatch? resolve(DriverCandidate candidate, DriverDeviceEvidence device) {
    final profiles =
        candidate.manifest.compatibility
            .map((profile) => _match(candidate, profile, device))
            .nonNulls
            .toList()
          ..sort(_compareProfiles);
    return profiles.firstOrNull;
  }

  DriverMatch? _match(
    DriverCandidate candidate,
    DriverCompatibility profile,
    DriverDeviceEvidence device,
  ) {
    final model = device.model;
    if (profile.models.isNotEmpty &&
        (model == null || !profile.models.any((name) => _same(name, model)))) {
      return null;
    }
    final details = [
      (profile.hardwareModel, device.hardwareModel),
      (profile.softwareVersion, device.softwareVersion),
      (profile.buildNumber, device.buildNumber),
      (profile.protocolVersion, device.protocolVersion),
    ];
    if (details.any((pair) => pair.$1 != null && pair.$1 != pair.$2)) {
      return null;
    }
    final platform = candidate.manifest.platform;
    if (!_matches(profile.osVersion, device.osVersion, _osVersions[platform]) ||
        !_matches(
          profile.firmwareVersion,
          device.firmwareVersion,
          _firmwareVersions[platform],
        )) {
      return null;
    }
    final firmware = profile.firmwareVersion;
    final range = firmware?.startsWith('>=') == true;
    return DriverMatch(
      candidate,
      profile,
      modelMatched: profile.models.isNotEmpty || profile.hardwareModel != null,
      firmwareExact: firmware != null && !range,
      firmwareRange: range,
      osMatched: profile.osVersion != null,
      matchedDetails: details.where((pair) => pair.$1 != null).length,
    );
  }

  static bool _matches(
    String? constraint,
    String? evidence,
    DeviceVersionComparator? compare,
  ) {
    if (constraint == null) {
      return true;
    }
    if (evidence == null) {
      return false;
    }
    if (!constraint.startsWith('>=')) {
      return constraint == evidence;
    }
    if (compare == null) {
      return false;
    }
    final bounds = _range.firstMatch(constraint);
    if (bounds == null || bounds.end != constraint.length) {
      return false;
    }
    final lower = compare(evidence, bounds[1]!);
    final upperBound = bounds[2];
    if (lower == null || lower < 0) {
      return false;
    }
    if (upperBound == null) {
      return true;
    }
    final upper = compare(evidence, upperBound);
    return upper != null && upper < 0;
  }

  static int _compareProfiles(DriverMatch a, DriverMatch b) {
    final evidence = b.compareEvidence(a);
    if (evidence != 0) {
      return evidence;
    }
    final version = b.profile.version.compareTo(a.profile.version);
    return version == 0 ? a.profile.id.compareTo(b.profile.id) : version;
  }

  static bool _same(String a, String b) => a.toLowerCase() == b.toLowerCase();

  static final _range = RegExp(r'^>=([^\s<>]+)(?: <([^\s<>]+))?$');
}
