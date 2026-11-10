import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_lg_webos/src/commands/services/lg_command_channel.dart';

final class LgApplicationController {
  LgApplicationController(this.channel, {this.endpoint});
  final Uri? endpoint;
  final LgCommandChannel channel;
  static const _settingsAppId = 'com.palm.app.settings';
  bool hasSettings = false;
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
    hasSettings = items.whereType<Map<String, dynamic>>().any(
      (item) => item['id'] == _settingsAppId,
    );
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
      apps.putIfAbsent(
        id,
        () => DeviceApplication(
          id,
          title.trim(),
          artwork: _artwork(item['icon']),
        ),
      );
    }
    _reported = Set.unmodifiable(apps.keys);
    return apps.values.toList();
  }

  Uri? _artwork(Object? value) {
    final host = endpoint?.host;
    if (value is! String || value.length > 1024 || host == null) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host != host ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return null;
    }
    return uri;
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

  Future<void> openAccessorySettings() async {
    if (!hasSettings) {
      throw const RemoteException(
        'unsupported',
        'The TV does not report a settings app.',
      );
    }
    await channel.send(
      RemoteCapability.accessorySettings,
      'system.launcher/launch',
      payload: {
        'id': _settingsAppId,
        'params': {'target': 'sound'},
      },
    );
  }
}
