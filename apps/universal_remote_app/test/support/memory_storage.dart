import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/domains/storage/contracts/application_storage.dart';

class MemoryStorage implements ApplicationStorage {
  final values = <String, String>{};
  final reads = <String>[];
  final writes = <String>[];
  @override
  Future<String?> read(String key) async {
    reads.add(key);
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writes.add(key);
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
