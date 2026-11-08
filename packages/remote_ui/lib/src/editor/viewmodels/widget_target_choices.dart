import 'package:remote_core/remote_core.dart';

import 'package:remote_ui/src/ui_model.dart';

import '../../rendering/viewmodels/grid_remote_viewmodel.dart';

final class WidgetTargetChoices {
  WidgetTargetChoices(this.dependencies, this.device);
  final RemoteEditorHost dependencies;
  final RemoteDevice device;
  final _cache = <String, List<(String, String)>>{};
  RemoteBase? _owner;

  Future<List<(String, String)>> load(String definitionId) async {
    final connection = dependencies.live.connection;
    if (connection.selected.value?.id != device.id ||
        connection.state.value != DeviceConnectionState.connected) {
      throw const RemoteException(
        'connection',
        'Connect this TV to choose its reported devices or shortcuts.',
      );
    }
    final owner = connection.controller;
    if (!identical(_owner, owner)) {
      _cache.clear();
      _owner = owner;
    }
    final cached = _cache[definitionId];
    if (cached != null) {
      return cached;
    }
    final choices = await _query(definitionId);
    if (!identical(owner, connection.controller) ||
        connection.state.value != DeviceConnectionState.connected) {
      throw const RemoteException(
        'connection',
        'The TV connection changed. Try again.',
      );
    }
    return _cache[definitionId] = List.unmodifiable(choices);
  }

  List<(String, String)>? cached(String definitionId) {
    if (!identical(_owner, dependencies.live.connection.controller) ||
        dependencies.live.connection.state.value !=
            DeviceConnectionState.connected) {
      return null;
    }
    return _cache[definitionId];
  }

  Future<List<(String, String)>> _query(String definitionId) async {
    final elements = RemoteItemRegistry.resolve(definitionId).elements;
    final collection = elements
        .whereType<RemoteCollection<TvRemoteDevice, Object>>()
        .firstOrNull;
    if (collection == null) {
      return const [];
    }
    return collection.options(GridRemoteViewModel(dependencies.live));
  }
}
