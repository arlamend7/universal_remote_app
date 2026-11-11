import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:remote_core/remote_core.dart';

/// Reads bounded artifacts from one configured HTTPS repository.
final class DriverHttpSource {
  DriverHttpSource(this.base, {bool allowLoopbackHttp = false}) {
    final loopback = InternetAddress.tryParse(base.host)?.isLoopback == true;
    final secure =
        base.scheme == 'https' ||
        (allowLoopbackHttp && loopback && base.scheme == 'http');
    if (!secure ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        !base.path.endsWith('/')) {
      throw ArgumentError('Expected a driver repository base URL.');
    }
  }

  final Uri base;

  Future<({Uint8List? bytes, String? etag})> read(
    String path, {
    required int maximum,
    String? etag,
    Future<void>? cancelled,
    void Function(int)? onBytes,
  }) async {
    final target = base.resolve(path);
    if (target.origin != base.origin ||
        !target.path.startsWith(base.path) ||
        target.userInfo.isNotEmpty ||
        target.hasQuery ||
        target.hasFragment) {
      throw ArgumentError('Invalid driver artifact path.');
    }
    final client = HttpClient()
      ..connectionTimeout = _timeout
      ..autoUncompress = false;
    try {
      return await Future.any([
        _read(client, target, maximum, etag, onBytes),
        if (cancelled != null)
          cancelled.then<Never>(
            (_) => throw const RemoteException(
              'cancelled',
              'Driver download cancelled.',
            ),
          ),
      ]).timeout(_timeout);
    } finally {
      client.close(force: true);
    }
  }

  static Future<({Uint8List? bytes, String? etag})> _read(
    HttpClient client,
    Uri target,
    int maximum,
    String? etag,
    void Function(int)? onBytes,
  ) async {
    final request = await client.getUrl(target);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    if (etag != null) {
      request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
    }
    final response = await request.close();
    if (response.statusCode == HttpStatus.notModified && etag != null) {
      return (bytes: null, etag: etag);
    }
    if (response.statusCode != HttpStatus.ok) {
      throw const RemoteException(
        'driverDownload',
        'Driver repository request failed.',
      );
    }
    if (response.contentLength > maximum) {
      throw const FormatException(
        'Driver artifact exceeds the download limit.',
      );
    }
    final content = BytesBuilder(copy: false);
    await for (final chunk in response) {
      if (content.length + chunk.length > maximum) {
        throw const FormatException(
          'Driver artifact exceeds the download limit.',
        );
      }
      content.add(chunk);
      onBytes?.call(content.length);
    }
    return (
      bytes: content.takeBytes(),
      etag: response.headers.value(HttpHeaders.etagHeader),
    );
  }

  static const _timeout = Duration(seconds: 20);
}
