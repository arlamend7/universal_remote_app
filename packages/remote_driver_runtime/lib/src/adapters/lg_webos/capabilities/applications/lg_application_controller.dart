import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/src/adapters/lg_webos/commands/services/lg_command_channel.dart';

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

  /// Launches an app by id. `id?contentId=…` opens content inside the app, and
  /// an http(s) address is opened by the TV's launcher.
  Future<void> launch(String target) async {
    if (target.trim().isEmpty) {
      throw ArgumentError('Application ID is required.');
    }
    final uri = Uri.tryParse(target);
    if (uri != null && {'http', 'https'}.contains(uri.scheme)) {
      return _open(uri);
    }
    final split = target.indexOf('?');
    final id = split < 0 ? target : target.substring(0, split);
    final contentId = split < 0
        ? null
        : _contentId(target.substring(split + 1));
    if (id.isEmpty || (split >= 0 && contentId == null)) {
      throw const RemoteException(
        'appLink',
        'Enter an app id, optionally followed by ?contentId=…, or a web address.',
      );
    }
    await channel.send(
      RemoteCapability.applications,
      'system.launcher/launch',
      payload: {'id': id, 'contentId': ?contentId},
    );
  }

  Future<void> _open(Uri uri) async {
    if (uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.toString().length > 1024) {
      throw const RemoteException('appLink', 'Enter a valid web address.');
    }
    await channel.send(
      RemoteCapability.applications,
      'system.launcher/open',
      payload: {'target': uri.toString()},
    );
  }

  String? _contentId(String query) {
    final Map<String, String> values;
    try {
      values = Uri.splitQueryString(query);
    } on FormatException {
      return null;
    }
    final id = values['contentId'];
    return values.length == 1 && id != null && id.isNotEmpty && id.length < 255
        ? id
        : null;
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
