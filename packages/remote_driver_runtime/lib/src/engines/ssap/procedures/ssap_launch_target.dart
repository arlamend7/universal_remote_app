import 'package:remote_core/remote_core.dart';

/// A launch request parsed from `appId`, `appId?contentId=…` or a web URL.
final class SsapLaunchTarget {
  const SsapLaunchTarget._({this.id, this.contentId, this.web});

  factory SsapLaunchTarget.parse(String target) {
    if (target.trim().isEmpty) {
      throw ArgumentError('Application ID is required.');
    }
    final uri = Uri.tryParse(target);
    if (uri != null && {'http', 'https'}.contains(uri.scheme)) {
      return SsapLaunchTarget._(web: _web(uri));
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
    return SsapLaunchTarget._(id: id, contentId: contentId);
  }

  final String? id;
  final String? contentId;
  final Uri? web;

  static Uri _web(Uri uri) {
    if (uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.toString().length > 1024) {
      throw const RemoteException('appLink', 'Enter a valid web address.');
    }
    return uri;
  }

  static String? _contentId(String query) {
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
}
