import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

void main() {
  test('shared TV contracts and domain enums have one core declaration', () {
    const names = {
      'RemoteBase',
      'TVRemoteBase',
      'ACRemoteBase',
      'RemoteDevice',
      'DeviceSoftwareInformation',
      'DeviceApplication',
      'DeviceChannel',
      'DeviceInput',
      'VolumeState',
      'CurrentContent',
      'RemoteCapability',
      'DeviceCategory',
      'DeviceConnectionState',
      'PairingState',
      'ProfileStage',
    };
    final declarations = <String, List<String>>{
      for (final name in names) name: [],
    };
    final types = RegExp(r'\b(?:class|enum)\s+(\w+)\b');
    for (final file in _productionDart()) {
      for (final match in types.allMatches(file.readAsStringSync())) {
        declarations[match[1]]?.add(file.path);
        expect(
          match[1],
          isNot(isIn(['TvRemoteDevice', 'RemoteDriver', 'SelectionStage'])),
        );
      }
    }
    for (final entry in declarations.entries) {
      expect(entry.value, hasLength(1), reason: entry.key);
      expect(entry.value.single, startsWith('packages/remote_core/lib/'));
    }
  });

  test('workspace dependency edges contain no package cycle', () {
    final graph = jsonDecode(
      File('docs/dependency-graph.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final packages = (graph['packages'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final local = {
      for (final package in packages)
        if (package['kind'] == 'root')
          package['name'] as String: (package['dependencies'] as List<Object?>)
              .cast<String>(),
    };
    for (final package in local.keys) {
      _visit(package, local, {});
    }
  });

  test(
    'external IDs stay extensible and finite types keep their wire values',
    () {
      expect(DeviceCategory.television.id, 'television');
      expect(PairingState.paired.id, 'paired');
      expect(DeviceCategory.tryParse('future-category'), isNull);
      expect(
        () => DeviceCategory.parse('future-category'),
        throwsFormatException,
      );
      expect(
        RuntimeOperations.navigation(NavigationKey.enter),
        'navigation-enter',
      );
      expect(
        RuntimeOperations.media(MediaAction.fastForward),
        'media-fast-forward',
      );
      final identity = IntegrationIdentity(
        integrationId: 'fixture.future-integration',
        providerId: 'new.vendor-tv',
      );
      expect(identity.providerId, 'new.vendor-tv');
    },
  );
}

Iterable<File> _productionDart() sync* {
  final directories = [
    ...Directory('packages').listSync().whereType<Directory>(),
    Directory('apps/universal_remote_app'),
  ];
  for (final directory in directories) {
    yield* Directory('${directory.path}/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
  }
}

void _visit(String package, Map<String, List<String>> local, Set<String> path) {
  expect(path.add(package), isTrue, reason: [...path, package].join(' → '));
  for (final dependency in local[package]!.where(local.containsKey)) {
    _visit(dependency, local, path);
  }
  path.remove(package);
}
