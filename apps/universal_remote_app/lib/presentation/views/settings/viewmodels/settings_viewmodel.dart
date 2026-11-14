import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';

final class SettingsViewModel {
  SettingsViewModel(this.dependencies);
  final AppDependencies dependencies;
  Listenable get changes => Listenable.merge([
    dependencies.settings.theme,
    dependencies.settings.accent,
    dependencies.settings.feedback,
    dependencies.settings.diagnostics,
    dependencies.settings.screenAwake,
    dependencies.settings.autoReconnect,
    dependencies.connection.state,
    dependencies.connection.selected,
  ]);
  String? get connectedDevice =>
      dependencies.connection.state.value == DeviceConnectionState.connected
      ? dependencies.connection.selected.value?.name
      : null;
  ThemeMode get theme => dependencies.settings.theme.value;
  int get accent => dependencies.settings.accent.value;
  bool get feedback => dependencies.settings.feedback.value;
  bool get supportsScreenAwake =>
      dependencies.settings.applyScreenAwake != null;
  bool get screenAwake => dependencies.settings.screenAwake.value;
  bool get autoReconnect => dependencies.settings.autoReconnect.value;

  Future<(bool, String?)> installDriverUpdates() async {
    final drivers = dependencies.drivers;
    if (drivers == null) {
      return (false, 'Driver downloads are unavailable.');
    }
    try {
      final catalog = await drivers.catalogs.cached();
      if (catalog == null) {
        return (false, 'Could not load driver updates. Try again.');
      }
      final report = await drivers.updates.installUpdates(catalog);
      await drivers.register(dependencies.providers);
      await dependencies.updateDriverAvailability();
      if (report.failed.isNotEmpty) {
        return (
          false,
          'Some driver updates could not be installed. Try again.',
        );
      }
      return (
        true,
        report.staged.isEmpty ? null : 'Reconnect your TV to apply the update.',
      );
    } on Exception {
      return (false, 'Could not install driver updates. Try again.');
    }
  }

  Future<void> setScreenAwake(BuildContext context, bool value) =>
      _protect(context, () => dependencies.settings.setScreenAwake(value));
  Future<void> setAutoReconnect(BuildContext context, bool value) =>
      _protect(context, () => dependencies.settings.setAutoReconnect(value));
  bool get diagnostics => dependencies.settings.diagnostics.value;
  Future<void> setTheme(BuildContext context, ThemeMode? mode) async {
    if (mode == null) {
      return;
    }
    await _protect(context, () => dependencies.settings.setTheme(mode));
  }

  Future<void> setFeedback(BuildContext context, bool enabled) =>
      _protect(context, () => dependencies.settings.setFeedback(enabled));

  Future<void> setAccent(BuildContext context, int value) =>
      _protect(context, () => dependencies.settings.setAccent(value));

  Future<void> setDiagnostics(BuildContext context, bool enabled) =>
      _protect(context, () => dependencies.settings.setDiagnostics(enabled));
  Future<void> _protect(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      _showError(context);
    }
  }

  void _showError(BuildContext context) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not save this change. Please retry.'),
      ),
    );
  }
}
