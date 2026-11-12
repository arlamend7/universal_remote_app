import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:route_definer/material.dart';

import '../app/app_dependencies.dart';
import '../presentation/containers/main/main_shell.dart';
import '../presentation/views/settings/settings_page.dart';
import '../presentation/views/devices/devices_page.dart';
import '../presentation/views/remote/remote_page.dart';

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
    router = createMaterialRouter(
      appTitle: 'Universal Remote',
      routes: [RouteDefiner<void>.simple(path: '/', builder: _home)],
    );
  }
  final AppDependencies dependencies;
  late final RouteDefinerRouter router;
  static const _remoteIndex = 0;
  static const _devicesIndex = 1;
  late final ValueNotifier<int> _selectedPage;
  late final _settings = SettingsPage(dependencies: dependencies);
  late final _devices = DevicesPage(
    dependencies: dependencies,
    onConnect: connect,
    onWake: wake,
  );

  void select(int destination) => _selectedPage.value = destination;
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

  Widget _home(BuildContext context) =>
      ValueListenableBuilder(valueListenable: _selectedPage, builder: _shell);

  Widget _shell(BuildContext context, int index, Widget? child) => MainShell(
    index: index,
    onSelect: select,
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
    router.dispose();
    _selectedPage.dispose();
  }
}
