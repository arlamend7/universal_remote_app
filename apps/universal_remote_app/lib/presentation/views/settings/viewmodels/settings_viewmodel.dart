import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';

import 'package:remote_ui/remote_ui.dart';

final class SettingsViewModel {
  SettingsViewModel(this.dependencies);
  final AppDependencies dependencies;
  Listenable get changes => Listenable.merge([
    dependencies.settings.theme,
    dependencies.settings.accent,
    dependencies.settings.feedback,
    dependencies.settings.diagnostics,
  ]);
  ThemeMode get theme => dependencies.settings.theme.value;
  int get accent => dependencies.settings.accent.value;
  bool get feedback => dependencies.settings.feedback.value;
  bool get diagnostics => dependencies.settings.diagnostics.value;
  Future<void> importOlderProfiles(BuildContext context) async {
    final importer = dependencies.importLegacyPreferences;
    if (importer == null) {
      return;
    }
    final confirmed = await ConfirmationDialog.ask(
      context,
      title: 'Import older saved TVs?',
      confirmLabel: 'Import',
      message: 'This reads settings and TV profiles saved by older versions. macOS may request Keychain permission. Pairing keys stay protected.',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await _protect(context, () => _importPreferences(importer));
  }

  Future<void> _importPreferences(Future<void> Function() importer) async {
    await importer();
    await dependencies.savedDevices.initialize();
    await dependencies.settings.initialize();
  }

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
