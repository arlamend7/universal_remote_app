import 'dart:io';
import 'dart:typed_data';

import 'package:remote_core/remote_core.dart';

Future<Uint8List?> loadTvArtwork(Uri uri) async {
  if (!{'http', 'https'}.contains(uri.scheme) ||
      !isLocalProbeAddress(uri.host) ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    return null;
  }
  final client = HttpClient()..findProxy = (_) => 'DIRECT';
  try {
    return await _read(client, uri).timeout(const Duration(seconds: 2));
  } on Exception {
    return null;
  } finally {
    client.close(force: true);
  }
}

Future<Uint8List?> _read(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  request.followRedirects = false;
  final response = await request.close();
  if (response.statusCode != 200 ||
      !{
        'png',
        'jpeg',
        'webp',
      }.contains(response.headers.contentType?.subType)) {
    return null;
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in response) {
    if (bytes.length + chunk.length > 256 * 1024) {
      return null;
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}
