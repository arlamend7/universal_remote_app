import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:remote_driver_manager/remote_driver_manager.dart';

/// Reads the signed driver seed bundled under `assets/driver-seed`.
///
/// The seed is generated from a verified publication by
/// `drivers/tools/publish/refresh_seed.py`; the app verifies it again with
/// its trusted keys before installing anything.
abstract final class AssetDriverSeed {
  static const _root = 'assets/driver-seed';

  static Future<SeedBundle?> load(AssetBundle bundle) async {
    final index = jsonDecode(await bundle.loadString('$_root/seed.json'));
    if (index is! Map<String, Object?>) {
      return null;
    }
    final catalog = index['catalog'];
    final objects = index['objects'];
    if (catalog is! String || objects is! List<Object?> || objects.isEmpty) {
      return null;
    }
    return SeedBundle(await bundle.loadString('$_root/$catalog'), {
      for (final sha in objects.whereType<String>())
        sha: (await bundle.load('$_root/objects/$sha.zip')).buffer
            .asUint8List(),
    });
  }
}
