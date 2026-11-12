import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:route_definer/material.dart';

import '../app/app_dependencies.dart';
import '../presentation/containers/main/main_shell.dart';
import '../presentation/views/settings/settings_page.dart';
import '../presentation/views/devices/devices_page.dart';
import '../presentation/views/remote/remote_page.dart';
import '../presentation/views/discovery/pages/device_preparation_page.dart';
import '../presentation/views/welcome/welcome_page.dart';
import '../presentation/views/network/startup_network_prompt.dart';
import '../presentation/views/session/session_prompt_coordinator.dart';

/// Route definitions and navigation decisions live outside presentation widgets.
final class AppRoutes {
  AppRoutes(this.dependencies) {
    final recent =
        dependencies.savedDevices.devices.value
            .where(
              (device) => device.metadata.containsKey(
                DeviceMetadataKeys.lastConnectedAt,
              ),
            )
            .toList()
          ..sort(
            (a, b) => a.metadata[DeviceMetadataKeys.lastConnectedAt]!.compareTo(
              b.metadata[DeviceMetadataKeys.lastConnectedAt]!,
            ),
          );
    _selectedPage = ValueNotifier(
      recent.isEmpty ? _devicesIndex : _remoteIndex,
    );
    if (recent.isNotEmpty) {
      dependencies.connection.selected.value ??= recent.last;
    }
    final saved = dependencies.savedDevices.devices;
    _startedWithoutDevices = saved.value.isEmpty;
    _settingUp = ValueNotifier(saved.value.isEmpty);
    saved.addListener(_redirectIfEmpty);
    final session = dependencies.session;
    _sessionPrompts = session == null
        ? null
        : SessionPromptCoordinator(
            session,
            dependencies.connection.state,
            dependencies.discovery.busy,
          );
    router = createMaterialRouter(
      appTitle: 'Universal Remote',
      observers: [if (_sessionPrompts case final prompts?) prompts],
      routes: [RouteDefiner<void>.simple(path: '/', builder: _home)],
    );
  }
  final AppDependencies dependencies;
  late final RouteDefinerRouter router;
  late final SessionPromptCoordinator? _sessionPrompts;
  static const _remoteIndex = 0;
  static const _devicesIndex = 1;
  static const _settingsIndex = 2;
  late final ValueNotifier<int> _selectedPage;
  late final ValueNotifier<bool> _settingUp;
  late final bool _startedWithoutDevices;
  bool _savingWelcome = false;
  late final _settings = SettingsPage(dependencies: dependencies);
  late final _devices = DevicesPage(
    dependencies: dependencies,
    onConnect: connect,
    onWake: wake,
  );

  void select(int destination) => _selectedPage.value = destination;

  void _selectTab(int destination) {
    final changed = destination != _selectedPage.value;
    select(destination);
    if (changed) {
      _sessionPrompts?.onTabChanged(
        stillAtBreak: destination == _settingsIndex
            ? () => _selectedPage.value == _settingsIndex
            : null,
      );
    }
  }

  void chooseDevice() => select(_devicesIndex);
  void connect(RemoteDevice device) {
    select(_remoteIndex);
    unawaited(dependencies.connection.connect(_savedConfiguration(device)));
  }

  void wake(RemoteDevice device) {
    select(_remoteIndex);
    unawaited(dependencies.connection.turnOn(_savedConfiguration(device)));
  }

  RemoteDevice _savedConfiguration(RemoteDevice device) {
    final saved = dependencies.savedDevices.byId(device.id);
    if (saved == null) {
      return device;
    }
    return dependencies.providers.mergeDiscovered(saved, device);
  }

  void _redirectIfEmpty() {
    if (dependencies.savedDevices.devices.value.isEmpty && !_settingUp.value) {
      _settingUp.value = true;
      select(_devicesIndex);
    }
  }

  Future<void> _finishWelcome(BuildContext context) async {
    if (_savingWelcome) {
      return;
    }
    _savingWelcome = true;
    try {
      _settingUp.value = dependencies.savedDevices.devices.value.isEmpty;
      await dependencies.settings.completeWelcome();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save setup progress. Please retry.'),
          ),
        );
      }
    } finally {
      _savingWelcome = false;
    }
  }

  void _finishDiscovery(RemoteDevice? device) {
    if (dependencies.savedDevices.devices.value.isEmpty) {
      return;
    }
    if (device != null) {
      connect(device);
    }
    _settingUp.value = false;
  }

  Widget _home(BuildContext context) => StartupNetworkPrompt(
    child: ListenableBuilder(
      listenable: Listenable.merge([
        _selectedPage,
        _settingUp,
        dependencies.settings.welcomeCompleted,
      ]),
      builder: _entry,
    ),
  );

  Widget _entry(BuildContext context, Widget? child) {
    if (_startedWithoutDevices &&
        !dependencies.settings.welcomeCompleted.value) {
      return WelcomePage(
        dependencies: dependencies,
        onContinue: _finishWelcome,
      );
    }
    if (_settingUp.value) {
      return DevicePreparationPage(
        dependencies: dependencies,
        onSetupFinished: _finishDiscovery,
      );
    }
    return _shell(context, _selectedPage.value, child);
  }

  Widget _shell(BuildContext context, int index, Widget? child) => MainShell(
    index: index,
    onSelect: _selectTab,
    session: _sessionPrompts,
    pages: [
      RemotePage(
        dependencies: dependencies,
        onChooseDevice: chooseDevice,
        active: index == _remoteIndex,
      ),
      _devices,
      _settings,
    ],
  );

  void dispose() {
    dependencies.savedDevices.devices.removeListener(_redirectIfEmpty);
    _sessionPrompts?.dispose();
    router.dispose();
    _settingUp.dispose();
    _selectedPage.dispose();
  }
}
