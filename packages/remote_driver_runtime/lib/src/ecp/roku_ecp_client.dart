import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:xml/xml.dart';

final class RokuEcpClient {
  RokuEcpClient(this.endpoint);

  final Uri endpoint;
  static const _timeout = Duration(seconds: 3);
  static const _maxResponse = 512 * 1024;

  Future<XmlElement> query(
    String name, {
    DiscoveryCancellation? cancellation,
  }) async {
    final body = await _request('GET', [
      'query',
      name,
    ], cancellation: cancellation);
    if (body.contains('<!DOCTYPE')) {
      throw const RemoteException(
        'protocol',
        'Roku returned an unsupported XML document.',
      );
    }
    try {
      return XmlDocument.parse(body).rootElement;
    } on FormatException {
      throw const RemoteException(
        'protocol',
        'Roku returned an invalid response.',
      );
    } on XmlException {
      throw const RemoteException(
        'protocol',
        'Roku returned an invalid response.',
      );
    }
  }

  Future<void> key(String name) async {
    await _request('POST', ['keypress', name]);
  }

  Future<void> launch(String id, {Map<String, String>? parameters}) async {
    await _request('POST', ['launch', id], query: parameters);
  }

  Future<String> _request(
    String method,
    List<String> path, {
    Map<String, String>? query,
    DiscoveryCancellation? cancellation,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = _timeout
      ..findProxy = (_) => 'DIRECT';
    if (cancellation != null) {
      unawaited(
        cancellation.whenCancelled.then((_) => client.close(force: true)),
      );
    }
    try {
      return await _exchange(client, method, path, query).timeout(_timeout);
    } on TimeoutException {
      throw const RemoteException(
        'timeout',
        'The Roku did not respond in time.',
      );
    } on IOException {
      throw const RemoteException(
        'network',
        'Could not reach the Roku on the local network.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _exchange(
    HttpClient client,
    String method,
    List<String> path,
    Map<String, String>? query,
  ) async {
    final request = await client.openUrl(
      method,
      endpoint.replace(pathSegments: path, queryParameters: query),
    );
    request.followRedirects = false;
    if (method == 'POST') {
      request.contentLength = 0;
    }
    final response = await request.close();
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const RemoteException(
        'permission',
        'Roku denied this operation. Check Control by mobile apps on the TV.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const RemoteException(
        'unsupported',
        'This operation is unavailable on the Roku.',
      );
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > _maxResponse) {
        throw const RemoteException(
          'protocol',
          'The Roku response was too large.',
        );
      }
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
