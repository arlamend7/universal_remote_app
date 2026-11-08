import 'dart:convert';

import 'package:remote_core/remote_core.dart';

import '../../devices/mappers/saved_device_mapper.dart';
import '../../../domains/storage/contracts/application_storage.dart';

/// Explicit, user-initiated migration; never reads Keychain during app startup.
final class LegacyPreferencesImporter {
  LegacyPreferencesImporter({required this.legacy, required this.preferences});
  final ApplicationStorage legacy;
  final ApplicationStorage preferences;
  Future<void> import() async {
    for (final key in const [
      'saved-devices.v1',
      'settings.theme',
      'settings.diagnostics',
    ]) {
      await _copyMissing(key);
    }
  }

  Future<void> _copyMissing(String key) async {
    if (await preferences.read(key) != null) {
      return;
    }
    final value = await legacy.read(key);
    if (value == null) {
      return;
    }
    _validate(key, value);
    await preferences.write(key, value);
    // Preserve the protected original; an interrupted import can be retried.
  }

  void _validate(String key, String value) {
    if (key != 'saved-devices.v1') {
      return;
    }
    try {
      final profiles = jsonDecode(value) as List<dynamic>;
      profiles.map(const SavedDeviceMapper().fromJson).toList();
    } catch (_) {
      throw const RemoteException(
        'profiles',
        'Older saved TVs could not be imported. Their original protected data has not been changed.',
      );
    }
  }
}
