import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../rendering/viewmodels/grid_remote_viewmodel.dart';

final class WidgetTargetChoices {
  WidgetTargetChoices(this.dependencies, this.device);
  final RemoteEditorHost dependencies;
  final RemoteDevice device;
  final _cache = <GridWidgetKind, List<(String, String)>>{};
  DeviceController? _owner;

  Future<List<(String, String)>> load(GridWidgetKind kind) async {
    final connection = dependencies.live.connection;
    if (connection.selected.value?.id != device.id ||
        connection.state.value != DeviceConnectionState.connected) {
      throw const RemoteException(
        'connection',
        'Connect this TV to choose its reported apps, inputs or channels.',
      );
    }
    final owner = connection.controller;
    if (!identical(_owner, owner)) {
      _cache.clear();
      _owner = owner;
    }
    final cached = _cache[kind];
    if (cached != null) {
      return cached;
    }
    final choices = await _query(kind);
    if (!identical(owner, connection.controller) ||
        connection.state.value != DeviceConnectionState.connected) {
      throw const RemoteException(
        'connection',
        'The TV connection changed. Try again.',
      );
    }
    return _cache[kind] = List.unmodifiable(choices);
  }

  List<(String, String)>? cached(GridWidgetKind kind) {
    if (!identical(_owner, dependencies.live.connection.controller) ||
        dependencies.live.connection.state.value !=
            DeviceConnectionState.connected) {
      return null;
    }
    return _cache[kind];
  }

  Future<List<(String, String)>> _query(GridWidgetKind kind) async {
    final elements = RemoteItemRegistry.resolve(kind).elements;
    final collection = elements
        .whereType<RemoteCollection<TvRemoteDevice, Object>>()
        .firstOrNull;
    if (collection == null) {
      return const [];
    }
    return collection.options(GridRemoteViewModel(dependencies.live));
  }
}
