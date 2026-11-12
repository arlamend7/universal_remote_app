import 'package:remote_core/remote_core.dart';

/// Everything an engine needs to open one authenticated device session.
final class EngineSessionContext {
  EngineSessionContext({
    required this.device,
    required this.credentials,
    required this.credentialKey,
    required this.connection,
    required this.onState,
    this.onPairingCode,
  });

  final RemoteDevice device;
  final CredentialStore credentials;

  /// Secure-storage key; device-scoped integrations use the device ID so the
  /// existing `client-key.v2.<deviceId>` credential keeps working.
  final String credentialKey;

  /// The validated `connection.json` section for this engine.
  final Map<String, Object?> connection;

  /// Reports pairing/connecting transitions while the session opens.
  final void Function(DeviceConnectionState state) onState;

  /// Called with a submitter while the TV waits for a code it displays, and
  /// with null once pairing ends; the controller forwards user codes to it.
  final void Function(Future<bool> Function(String code)? submit)?
  onPairingCode;
}
