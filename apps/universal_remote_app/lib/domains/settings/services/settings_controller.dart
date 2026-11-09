import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';
import 'package:universal_remote_app/domains/diagnostics/services/diagnostic_logger.dart';
import 'package:universal_remote_app/domains/storage/contracts/application_storage.dart';

class SettingsController {
  SettingsController(this.storage, this.logger, {this.applyScreenAwake});
  final ApplicationStorage storage;
  final DiagnosticLogger logger;
  final Future<void> Function(bool)? applyScreenAwake;
  final screenAwake = ValueNotifier(false);
  final autoReconnect = ValueNotifier(true);
  final theme = ValueNotifier(ThemeMode.dark);
  final diagnostics = ValueNotifier(false);
  final feedback = ValueNotifier(true);
  final accent = ValueNotifier<int>(_defaultAccent);
  static const _defaultAccent = 0xff245b45;
  Future<void> initialize() async {
    final raw = await storage.read('settings.theme');
    theme.value =
        ThemeMode.values.where((e) => e.name == raw).firstOrNull ??
        ThemeMode.dark;
    final storedAccent = int.tryParse(
      await storage.read('settings.accent') ?? '',
    );
    accent.value = storedAccent ?? _defaultAccent;
    feedback.value = await storage.read('settings.feedback') != 'false';
    RemoteFeedback.enabled = feedback.value;
    diagnostics.value = await storage.read('settings.diagnostics') == 'true';
    logger.enabled = diagnostics.value;
    autoReconnect.value =
        await storage.read('settings.autoReconnect') != 'false';
    await _restoreScreenAwake();
  }

  Future<void> _restoreScreenAwake() async {
    final apply = applyScreenAwake;
    if (apply == null || await storage.read('settings.screenAwake') != 'true') {
      return;
    }
    try {
      await apply(true);
      screenAwake.value = true;
    } catch (_) {
      screenAwake.value = false;
    }
  }

  Future<void> setScreenAwake(bool value) async {
    final apply = applyScreenAwake;
    if (apply == null) {
      return;
    }
    await apply(value);
    try {
      await storage.write('settings.screenAwake', '$value');
    } catch (_) {
      await apply(screenAwake.value);
      rethrow;
    }
    screenAwake.value = value;
  }

  Future<void> setAutoReconnect(bool value) async {
    await storage.write('settings.autoReconnect', '$value');
    autoReconnect.value = value;
  }

  Future<void> setTheme(ThemeMode value) async {
    await storage.write('settings.theme', value.name);
    theme.value = value;
  }

  Future<void> setFeedback(bool value) async {
    await storage.write('settings.feedback', '$value');
    feedback.value = value;
    RemoteFeedback.enabled = value;
  }

  Future<void> setAccent(int value) async {
    await storage.write('settings.accent', '$value');
    accent.value = value;
  }

  Future<void> setDiagnostics(bool value) async {
    await storage.write('settings.diagnostics', '$value');
    diagnostics.value = value;
    logger.enabled = value;
  }

  void dispose() {
    theme.dispose();
    accent.dispose();
    screenAwake.dispose();
    autoReconnect.dispose();
    feedback.dispose();
    diagnostics.dispose();
  }
}
