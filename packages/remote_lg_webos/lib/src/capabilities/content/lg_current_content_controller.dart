import 'package:remote_core/remote_core.dart';

import '../../commands/services/lg_command_channel.dart';

/// Optional feedback: errors here must never revoke navigation or volume.
final class LgCurrentContentController {
  LgCurrentContentController(this.channel);
  final LgCommandChannel channel;
  final _titles = <String, String>{};
  bool _loadedTitles = false;
  static const _foreground =
      'com.webos.applicationManager/getForegroundAppInfo';
  Future<CurrentContent> currentContent() async =>
      _decode(await channel.query(_foreground));
  Stream<CurrentContent> watchCurrentContent() =>
      channel.subscribe(_foreground).asyncMap(_decode);

  Future<CurrentContent> _decode(Map<String, Object?> response) async {
    final id = response['appId'];
    if (id is! String || id.isEmpty) {
      throw const RemoteException(
        'content',
        'The TV did not report its current app.',
      );
    }
    await _loadTitles();
    final name =
        _text(response['appName']) ?? _text(response['title']) ?? _titles[id];
    if (id != 'com.webos.app.livetv') {
      return CurrentContent(appId: id, appName: name);
    }
    return _liveChannel(id, name);
  }

  Future<CurrentContent> _liveChannel(String id, String? name) async {
    try {
      final response = await channel.query('tv/getCurrentChannel');
      return CurrentContent(
        appId: id,
        appName: name ?? 'Live TV',
        channelName: _text(response['channelName']),
        channelNumber: _text(response['channelNumber']),
      );
    } on RemoteException {
      return CurrentContent(appId: id, appName: name ?? 'Live TV');
    }
  }

  Future<void> _loadTitles() async {
    if (_loadedTitles) {
      return;
    }
    _loadedTitles = true;
    try {
      final response = await channel.query(
        'com.webos.applicationManager/listApps',
      );
      _rememberTitles(response['apps']);
    } on RemoteException {
      // Names are optional; a reported ID remains useful without a title.
    }
  }

  void _rememberTitles(Object? apps) {
    if (apps is! List) {
      return;
    }
    for (final app in apps.whereType<Map<String, dynamic>>()) {
      final id = _text(app['id']);
      final title = _text(app['title']);
      if (id != null && title != null) {
        _titles[id] = title;
      }
    }
  }

  String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
