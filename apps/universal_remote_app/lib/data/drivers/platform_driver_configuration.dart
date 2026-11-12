import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

/// Builds the integration service from build-time configuration and the
/// platform's private driver storage and signature verifier.
abstract final class PlatformDriverConfiguration {
  static const _channel = MethodChannel(
    'br.net.devcom.universal_remote/drivers',
  );

  /// Development integrations (such as Roku ECP) are offered only by
  /// non-release builds that opt in.
  static const allowDevelopment =
      !kReleaseMode && bool.fromEnvironment('ALLOW_DEVELOPMENT_INTEGRATIONS');

  static ProtocolEngineRegistry engines() => ProtocolEngineRegistry([
    SsapEngine(),
    RemoteV2Engine(),
    SamsungChannelEngine(),
    RokuEcpEngine(),
    JsonWebSocketEngine(),
  ]);

  static Future<IntegrationService?> load(CredentialStore credentials) async {
    const local = String.fromEnvironment('DRIVER_LOCAL_PATH');
    if (!kReleaseMode && local.isNotEmpty) {
      return _local(local, credentials);
    }
    const url = String.fromEnvironment('DRIVER_CATALOG_BASE_URL');
    const keys = String.fromEnvironment('DRIVER_TRUSTED_KEYS');
    if (keys.isEmpty ||
        !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return null;
    }
    final path = await _storageDirectory();
    return IntegrationService(
      root: Directory('$path/installed-drivers'),
      legacyRoot: Directory(path),
      engines: engines(),
      credentials: credentials,
      verify: _verifier(keys),
      source: url.isEmpty ? null : DriverHttpSource(Uri.parse(url)),
      allowDevelopment: allowDevelopment,
    );
  }

  static Future<IntegrationService> _local(
    String folder,
    CredentialStore credentials,
  ) async {
    final path = await _storageDirectory();
    final service = IntegrationService(
      root: Directory('$path/development'),
      engines: engines(),
      credentials: credentials,
      verify: (_, _, _) async => false,
      allowDevelopment: true,
    );
    await service.installLocalFolder(Directory(folder));
    return service;
  }

  static DriverSignatureVerifier _verifier(String keys) {
    final values = jsonDecode(keys);
    if (values is! Map<String, Object?> || values.isEmpty) {
      throw const FormatException('Invalid driver trust configuration.');
    }
    final trusted = values.map(_decodeKey);
    return (keyId, payload, signature) async {
      final key = trusted[keyId];
      if (key == null) {
        return false;
      }
      return await _channel.invokeMethod<bool>('verify', {
            'key': key,
            'payload': payload,
            'signature': signature,
          }) ??
          false;
    };
  }

  static Future<String> _storageDirectory() async {
    final path = await _channel.invokeMethod<String>('storageDirectory');
    if (path == null || path.isEmpty) {
      throw StateError('Private driver storage is unavailable.');
    }
    return path;
  }

  static MapEntry<String, Uint8List> _decodeKey(String id, Object? value) {
    if (value is! String) {
      throw const FormatException('Invalid driver public key.');
    }
    final key = base64Decode(value);
    if (key.length != 65 || key.first != 4) {
      throw const FormatException('Expected an uncompressed P-256 public key.');
    }
    return MapEntry(id, key);
  }
}
