import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:remote_driver_manager/remote_driver_manager.dart';

abstract final class PlatformDriverConfiguration {
  static const _channel = MethodChannel(
    'br.net.devcom.universal_remote/drivers',
  );

  static Future<ManagedDriverService?> load() async {
    const local = String.fromEnvironment('DRIVER_LOCAL_PATH');
    if (!kReleaseMode && local.isNotEmpty) {
      return _local(local);
    }
    const url = String.fromEnvironment('DRIVER_CATALOG_BASE_URL');
    const keys = String.fromEnvironment('DRIVER_TRUSTED_KEYS');
    if (url.isEmpty ||
        keys.isEmpty ||
        !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return null;
    }
    final values = jsonDecode(keys);
    if (values is! Map<String, Object?> || values.isEmpty) {
      throw const FormatException('Invalid driver trust configuration.');
    }
    final trusted = values.map(_decodeKey);
    final path = await _storageDirectory();
    final source = DriverHttpSource(Uri.parse(url));
    final storage = DriverPackageStorage(Directory(path));
    Future<bool> verify(
      String keyId,
      Uint8List payload,
      Uint8List signature,
    ) async {
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
    }

    final catalogs = DriverCatalogRepository(source, storage, verify);
    final packages = HttpDriverPackageRepository(source, catalogs, verify);
    final manager = DriverManager(storage, packages);
    return ManagedDriverService(
      manager,
      catalogs,
      updates: DriverUpdateService(manager, storage),
    );
  }

  static Future<ManagedDriverService> _local(String path) async {
    final repository = await LocalDriverPackageRepository.open(
      Directory(path),
      enabled: !kReleaseMode,
    );
    final directory = await _storageDirectory();
    final storage = DriverPackageStorage(Directory('$directory/development'));
    final manager = DriverManager(storage, repository);
    await manager.initialize();
    await manager.install(repository.package.identity);
    return ManagedDriverService(manager, null);
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
