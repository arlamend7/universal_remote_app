import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/ssap.dart';

/// Capability controllers depend on a session channel, never the device owner.
final class LgCommandChannel {
  LgCommandChannel({required this.onUnavailable, this.bindings});
  final DriverBindings? bindings;
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
      return await client.request(
        _boundPath(path),
        payload: payload,
        timeout: timeout,
      );
    } on RemoteException catch (error) {
      if (identical(client, _client)) {
        _handleFailure(capability, error);
      }
      rethrow;
    }
  }

  /// A failed status query does not establish that write commands are denied.
  Future<Map<String, Object?>> query(String path) {
    final client = _client;
    if (client == null) {
      throw const RemoteException('disconnected', 'Connect to the TV first.');
    }
    return client.request(_boundPath(path));
  }

  Stream<Map<String, Object?>> subscribe(
    String path, {
    RemoteCapability? capability,
  }) async* {
    final client = _client;
    if (client == null) {
      throw const RemoteException('disconnected', 'Connect to the TV first.');
    }
    try {
      yield* client.subscribe(_boundPath(path));
    } on RemoteException catch (error) {
      if (capability != null && identical(client, _client)) {
        _handleFailure(capability, error);
      }
      rethrow;
    }
  }

  String _boundPath(String path) => path;

  void _handleFailure(RemoteCapability capability, RemoteException error) {
    if (error.code != 'unsupported' && error.code != 'permission') {
      return;
    }
    onUnavailable(capability);
  }
}
