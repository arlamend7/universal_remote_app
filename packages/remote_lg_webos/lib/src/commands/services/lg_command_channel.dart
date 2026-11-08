import 'package:remote_core/remote_core.dart';

import '../../protocol/services/ssap_client.dart';

/// Capability controllers depend on a session channel, never the device owner.
final class LgCommandChannel {
  LgCommandChannel({required this.onUnavailable});
  final void Function(RemoteCapability) onUnavailable;
  SsapClient? _client;
  void attach(SsapClient client) {
    _client = client;
  }

  void detach() {
    _client = null;
  }

  Future<Map<String, Object?>> send(
    RemoteCapability capability,
    String path, {
    Map<String, Object?> payload = const {},
    Duration? timeout,
  }) async {
    final client = _client;
    if (client == null) {
      throw const RemoteException('disconnected', 'Connect to the TV first.');
    }
    try {
      return await client.request(path, payload: payload, timeout: timeout);
    } on RemoteException catch (error) {
      _handleFailure(capability, error);
      rethrow;
    }
  }

  /// A failed status query does not establish that write commands are denied.
  Future<Map<String, Object?>> query(String path) {
    final client = _client;
    if (client == null) {
      throw const RemoteException('disconnected', 'Connect to the TV first.');
    }
    return client.request(path);
  }

  Stream<Map<String, Object?>> subscribe(String path) {
    final client = _client;
    if (client != null) {
      return client.subscribe(path);
    }
    return Stream.error(
      const RemoteException('disconnected', 'Connect to the TV first.'),
    );
  }

  void _handleFailure(RemoteCapability capability, RemoteException error) {
    if (error.code != 'unsupported' && error.code != 'permission') {
      return;
    }
    onUnavailable(capability);
  }
}
