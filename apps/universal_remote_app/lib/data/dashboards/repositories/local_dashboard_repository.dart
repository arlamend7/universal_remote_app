import 'package:remote_ui/remote_ui.dart';

import 'dart:convert';

import '../../../domains/storage/contracts/application_storage.dart';

final class LocalDashboardRepository implements DashboardRepository {
  const LocalDashboardRepository(this.storage);

  static const storageKey = 'dashboards.v1';
  final ApplicationStorage storage;

  @override
  Future<Map<String, String>> load() async {
    final raw = await storage.read(storageKey);
    if (raw == null) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }
      return {
        for (final entry in decoded.entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> save(Map<String, String> dashboards) =>
      storage.write(storageKey, jsonEncode(dashboards));
}
