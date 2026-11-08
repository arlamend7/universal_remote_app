import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/src/commands/services/lg_command_channel.dart';

final class LgApplicationController {
  LgApplicationController(this.channel);
  final LgCommandChannel channel;
  Set<String>? _reported;
  Set<String>? get reportedApplicationIds => _reported;
  Future<List<DeviceApplication>> applications() async {
    final response = await channel.send(
      RemoteCapability.applications,
      'com.webos.applicationManager/listApps',
    );
    final items = response['apps'];
    if (items is! List) {
      throw const RemoteException(
        'protocol',
        'The TV returned an invalid application list.',
      );
    }
    final apps = <String, DeviceApplication>{};
    for (final item in items.whereType<Map<String, dynamic>>()) {
      final id = item['id'];
      final title = item['title'];
      if (item['visible'] == false ||
          id is! String ||
          id.trim().isEmpty ||
          title is! String ||
          title.trim().isEmpty) {
        continue;
      }
      apps.putIfAbsent(id, () => DeviceApplication(id, title.trim()));
    }
    _reported = Set.unmodifiable(apps.keys);
    return apps.values.toList();
  }

  Future<void> launch(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Application ID is required.');
    }
    await channel.send(
      RemoteCapability.applications,
      'system.launcher/launch',
      payload: {'id': id},
    );
  }

  Future<String?> currentApplication() async {
    final value = await channel.send(
      RemoteCapability.applications,
      'com.webos.applicationManager/getForegroundAppInfo',
    );
    return value['appId'] as String?;
  }
}
