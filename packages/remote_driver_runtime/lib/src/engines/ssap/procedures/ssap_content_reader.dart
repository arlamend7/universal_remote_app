import 'package:remote_core/remote_core.dart';

import '../../contracts/content_reading.dart';
import '../operations/ssap_operation.dart';

typedef SsapQuery = Future<Map<String, Object?>> Function(String uri);

/// Decodes the foreground app, its title and, for the declared live-TV app,
/// the current channel. Errors in optional lookups never fail the reading.
final class SsapContentReader {
  SsapContentReader(this._query);

  final SsapQuery _query;
  final _titles = <String, String>{};
  bool _loadedTitles = false;

  Future<ContentReading> read(SsapOperation operation) async =>
      decode(operation, await _query(operation.uri));

  Future<ContentReading> decode(
    SsapOperation operation,
    Map<String, Object?> response,
  ) async {
    final id = response['appId'];
    if (id is! String || id.isEmpty) {
      throw const RemoteException(
        'content',
        'The TV did not report its current app.',
      );
    }
    final input = _input(operation, id);
    await _loadTitles(operation.string('applicationsUri'));
    final name =
        _text(response['appName']) ?? _text(response['title']) ?? _titles[id];
    final content = id == operation.string('liveTvApplicationId')
        ? await _liveChannel(operation, id, name)
        : CurrentContent(appId: id, appName: name);
    return ContentReading(
      content,
      input: input,
      reportsInput: operation.string('inputApplicationPrefix') != null,
    );
  }

  DeviceInput? _input(SsapOperation operation, String appId) {
    final prefix = operation.string('inputApplicationPrefix');
    if (prefix == null || !appId.startsWith(prefix)) {
      return null;
    }
    final number = appId.substring(prefix.length);
    if (!RegExp(r'^\d{1,2}$').hasMatch(number)) {
      return null;
    }
    return DeviceInput(
      '${operation.string('inputIdPrefix') ?? ''}$number',
      '${operation.string('inputNamePrefix') ?? ''}$number',
    );
  }

  Future<CurrentContent> _liveChannel(
    SsapOperation operation,
    String id,
    String? name,
  ) async {
    final uri = operation.string('channelUri');
    if (uri == null) {
      return CurrentContent(appId: id, appName: name, liveTv: true);
    }
    try {
      final response = await _query(uri);
      return CurrentContent(
        appId: id,
        appName: name ?? 'Live TV',
        liveTv: true,
        channelName: _text(response['channelName']),
        channelNumber: _text(response['channelNumber']),
      );
    } on RemoteException {
      return CurrentContent(
        appId: id,
        appName: name ?? 'Live TV',
        liveTv: true,
      );
    }
  }

  Future<void> _loadTitles(String? uri) async {
    if (_loadedTitles || uri == null) {
      return;
    }
    _loadedTitles = true;
    try {
      _rememberTitles((await _query(uri))['apps']);
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

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
