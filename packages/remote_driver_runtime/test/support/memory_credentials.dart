import 'dart:async';

import 'package:remote_core/remote_core.dart';

final class MemoryCredentials implements CredentialStore {
  final values = <String, String>{};
  int reads = 0;
  @override
  Future<String?> read(String id) async {
    reads++;
    return values[id];
  }

  @override
  Future<void> write(String id, String key) async {
    values[id] = key;
  }

  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }
}
