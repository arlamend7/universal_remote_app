import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// A loopback repository serving fixed artifacts and counting requests.
final class StaticDriverServer {
  final files = <String, Uint8List>{};
  final requests = <String>[];
  HttpServer? _server;

  Uri get base => Uri.parse('http://127.0.0.1:${_server!.port}/drivers/');

  Future<void> start() async {
    final server = _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    server.listen(_answer);
  }

  Future<void> close() async => _server?.close(force: true);

  void _answer(HttpRequest request) {
    final path = request.uri.path.replaceFirst('/drivers/', '');
    requests.add(path);
    final body = files[path];
    if (body == null) {
      request.response.statusCode = HttpStatus.notFound;
    }
    if (body != null) {
      request.response.add(body);
    }
    unawaited(request.response.close());
  }
}
