import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_network/remote_network.dart';
import 'package:test/test.dart';

final _generic = DriverCompatibility(id: 'generic', version: 1, models: []);
final _range = DriverCompatibility(
  id: 'range',
  version: 1,
  models: ['EX-42'],
  osVersion: 'OS-3',
  firmwareVersion: '>=FW_008 <FW_012',
);
final _exact = DriverCompatibility(
  id: 'exact',
  version: 1,
  models: ['EX-42'],
  firmwareVersion: 'FW_009',
);

DriverDeviceEvidence _device({String? firmware, String? os, String? model}) =>
    DriverDeviceEvidence.fromDevice(
      RemoteDevice(
        id: 'fictional',
        providerId: 'example.tv',
        name: 'Test TV',
        manufacturer: 'Example',
        model: model,
        category: DeviceCategory.television,
        endpoints: [Uri.parse('wss://192.168.1.2:9000')],
      ),
      osVersion: os,
      firmwareVersion: firmware,
    );

DriverCandidate _candidate(
  String version, {
  String id = 'example.tv',
  bool installed = false,
  String runtime = '>=1.0.0',
  String provider = 'example.tv',
  String platform = 'ExampleOS',
  List<DriverCompatibility>? profiles,
  List<DriverOperation> operations = const [DriverOperation.webSocketConnect],
}) => DriverCandidate(
  DriverManifest(
    identity: DriverIdentity(
      id: id,
      providerId: provider,
      version: DriverVersion.parse(version),
    ),
    name: 'Example TV',
    manufacturer: 'Example',
    platform: platform,
    runtime: DriverRuntimeRequirements.parse(runtime, operations),
    capabilities: const [],
    compatibility: profiles ?? [_generic],
  ),
  installed: installed,
);

int? _compareFirmware(String a, String b) {
  final format = RegExp(r'^FW_([0-9]{3})$');
  final left = format.firstMatch(a);
  final right = format.firstMatch(b);
  if (left == null || right == null) {
    return null;
  }
  return int.parse(left[1]!).compareTo(int.parse(right[1]!));
}

void main() {
  final resolver = DriverResolver(
    runtimeVersion: DriverVersion.parse('1.1.0'),
    operations: [DriverOperation.webSocketConnect],
    compatibility: DriverCompatibilityResolver(
      firmwareVersions: {'ExampleOS': _compareFirmware},
    ),
  );

  test('uses exact model and firmware before a range or generic fallback', () {
    final driver = _candidate('1.0.0', profiles: [_range, _generic, _exact]);
    final exact = resolver.resolve(
      _device(firmware: 'FW_009', os: 'OS-3', model: 'ex-42'),
      [driver],
    );
    expect(exact.selected?.profile.id, 'exact');
    final range = resolver.resolve(
      _device(firmware: 'FW_010', os: 'OS-3', model: 'EX-42'),
      [driver],
    );
    expect(range.selected?.profile.id, 'range');
    expect(range.selected?.firmwareRange, isTrue);
    for (final firmware in [null, 'FW_012', 'other-vendor-version']) {
      final generic = resolver.resolve(
        _device(firmware: firmware, os: 'OS-3', model: 'EX-42'),
        [driver],
      );
      expect(generic.selected?.isGeneric, isTrue);
    }
  });

  test('only recognized firmware formats satisfy a platform range', () {
    final driver = _candidate(
      '1.0.0',
      platform: 'webOS',
      profiles: [
        _generic,
        DriverCompatibility(
          id: 'three-part',
          version: 1,
          models: const [],
          firmwareVersion: '>=04.09.00 <05.00.00',
          protocolVersion: 'SSAP',
        ),
      ],
    );
    String? resolve(String firmware, String? protocol) {
      final device = RemoteDevice(
        id: 'fixture',
        providerId: 'example.tv',
        name: 'Fixture',
        endpoints: const [],
        softwareInformation: DeviceSoftwareInformation(
          source: DeviceInformationSource.authenticatedSession,
          firmwareVersion: firmware,
          protocolVersion: protocol,
        ),
      );
      return DriverCompatibilityResolver()
          .resolve(driver, DriverDeviceEvidence.fromDevice(device))
          ?.profile
          .id;
    }

    expect(resolve('04.10.00', 'SSAP'), 'three-part');
    expect(resolve('04.09.00', 'SSAP'), 'three-part');
    expect(resolve('05.00.00', 'SSAP'), 'generic');
    expect(resolve('04.10.00-build', 'SSAP'), 'generic');
    expect(resolve('04.10.00', null), 'generic');
  });

  test('chooses an installed driver locally and finds a compatible update', () {
    final candidates = [
      _candidate('1.2.0'),
      _candidate('2.0.0', runtime: '>=2.0.0'),
      _candidate('1.0.0', installed: true),
      _candidate('1.3.0', operations: [DriverOperation.webSocketPair]),
      _candidate('1.4.0', profiles: [_exact]),
      _candidate('1.5.0', provider: 'other.tv'),
    ];
    final local = resolver.resolve(_device(), candidates);
    expect(local.selected?.candidate.identity.version.toString(), '1.0.0');
    expect(local.selected?.needsInstallation, isFalse);
    final update = resolver.resolve(
      _device(),
      candidates,
      preferInstalled: false,
    );
    expect(update.selected?.candidate.identity.version.toString(), '1.2.0');
    expect(update.selected?.needsInstallation, isTrue);
    expect(
      update.rejected.map((item) => item.reason),
      containsAll([
        DriverRejectionReason.runtimeVersion,
        DriverRejectionReason.missingOperations,
        DriverRejectionReason.deviceCompatibility,
        DriverRejectionReason.providerMismatch,
      ]),
    );
    expect(
      update.rejected
          .singleWhere(
            (item) => item.reason == DriverRejectionReason.missingOperations,
          )
          .missingOperations,
      {DriverOperation.webSocketPair},
    );
  });

  test(
    'equal evidence across families requires a deterministic choice list',
    () {
      final candidates = [
        _candidate('2.0.0', id: 'example.second'),
        _candidate('1.0.0', id: 'example.first'),
      ];
      for (final order in [candidates, candidates.reversed]) {
        final result = resolver.resolve(_device(), order);
        expect(result.requiresSelection, isTrue);
        expect(result.selected, isNull);
        expect(result.alternatives.map((item) => item.candidate.identity.id), [
          'example.first',
          'example.second',
        ]);
      }
    },
  );
}
