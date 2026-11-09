import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../repositories/device_profile_repository.dart';

class SavedDevicesController {
  SavedDevicesController(this.repository, this.credentials);
  final DeviceProfileRepository repository;
  final CredentialStore credentials;
  final _registry = const DeviceRegistry();
  List<RegisteredDevice> _registered = [];
  Iterable<RegisteredDevice> get registered => _registered;
  final devices = ValueNotifier<List<RemoteDevice>>([]);
  Future<void>? _writes;
  bool _closing = false;
  Future<void> _write(Future<void> Function() action) {
    if (_closing) {
      return Future.error(StateError('Device profiles are closed.'));
    }
    final previous = _writes;
    final result = previous == null
        ? Future<void>.sync(action)
        : previous.then((_) => action());
    final settled = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _writes = settled;
    unawaited(
      settled.then((_) {
        if (identical(_writes, settled)) {
          _writes = null;
        }
      }),
    );
    return result;
  }

  /// The current saved record, or null when [id] is not saved.
  RegisteredDevice? logicalDevice(String? id) =>
      _registry.find(_registered, id);

  RemoteDevice? byId(String? id) {
    final logical = logicalDevice(id);
    if (logical == null) {
      return null;
    }
    final profile = logical.profiles
        .where((profile) => profile.id == id)
        .firstOrNull;
    return copyDevice(
      (profile ?? logical.preferredProfile).device,
      name: logical.name,
    );
  }

  Future<void> updateExisting(
    String id,
    RemoteDevice? Function(RemoteDevice) update,
  ) => _write(() async {
    final current = byId(id);
    if (current == null) {
      return;
    }
    final changed = update(current);
    if (changed != null) {
      await _save(changed);
    }
  });
  Future<void> initialize() async {
    _publish(await repository.loadRegistered());
  }

  Future<void> save(RemoteDevice device) => _write(() => _save(device));
  Future<void> _save(RemoteDevice device) {
    final current = logicalDevice(device.id);
    if (current == null) {
      return _persist([..._registered, _registry.fromProfile(device)]);
    }
    final profile = current.profiles
        .where((profile) => profile.id == device.id)
        .first;
    final configuration = profile.userAssociated
        ? copyDevice(device, name: profile.device.name)
        : device;
    return _replace(_registry.update(current, configuration));
  }

  Future<void> _replace(RegisteredDevice device) => _persist(
    _registered
        .map((current) => current.id == device.id ? device : current)
        .toList(),
  );

  Future<void> _persist(List<RegisteredDevice> next) async {
    await repository.saveRegistered(next);
    _publish(next);
  }

  void _publish(List<RegisteredDevice> next) {
    _registered = List.unmodifiable(next);
    devices.value = [
      for (final device in _registered)
        copyDevice(device.preferredProfile.device, name: device.name),
    ];
  }

  Future<void> rename(RemoteDevice device, String name) async {
    if (name.trim().isEmpty) {
      throw const RemoteException('name', 'Enter a device name.');
    }
    await _write(() async {
      final current = logicalDevice(device.id);
      if (current == null) {
        return;
      }
      await _replace(
        RegisteredDevice(
          id: current.id,
          name: name.trim(),
          category: current.category,
          profiles: current.profiles,
          preferredProviderId: current.preferredProviderId,
        ),
      );
    });
  }

  Future<void> preferProvider(String id, String providerId) => _write(() async {
    final current = logicalDevice(id);
    if (current == null) {
      return;
    }
    await _replace(
      RegisteredDevice(
        id: current.id,
        name: current.name,
        category: current.category,
        profiles: current.profiles,
        preferredProviderId: providerId,
      ),
    );
  });

  Iterable<RegisteredDevice> associationCandidates(String id) {
    final current = logicalDevice(id);
    if (current == null || current.category == DeviceCategory.unknown) {
      return const [];
    }
    final providers = current.profiles
        .map((profile) => profile.providerId)
        .toSet();
    return _registered.where(
      (candidate) =>
          candidate.id != current.id &&
          candidate.category == current.category &&
          candidate.profiles.length == 1 &&
          candidate.preferredProfile.confirmed &&
          !providers.contains(candidate.preferredProfile.providerId),
    );
  }

  Future<void> associate(String id, String otherId) => _write(() async {
    final current = logicalDevice(id);
    final other = associationCandidates(id)
        .where((candidate) => candidate.id == otherId)
        .firstOrNull;
    if (current == null || other == null) {
      throw const RemoteException(
        'profileAssociation',
        'These profiles cannot be linked.',
      );
    }
    final profile = other.preferredProfile;
    final updated = RegisteredDevice(
      id: current.id,
      name: current.name,
      category: current.category,
      preferredProviderId: current.preferredProviderId,
      profiles: [
        ...current.profiles,
        ConnectionProfile(
          profile.device,
          confirmed: profile.confirmed,
          userAssociated: true,
        ),
      ],
    );
    await _persist(
      _registered
          .where((device) => device.id != other.id)
          .map((device) => device.id == current.id ? updated : device)
          .toList(),
    );
  });

  Future<void> detach(String id, String profileId) => _write(() async {
    final current = logicalDevice(id);
    final profile = current?.profiles
        .where((profile) => profile.id == profileId && profile.userAssociated)
        .firstOrNull;
    if (current == null || profile == null) {
      throw const RemoteException(
        'profileAssociation',
        'This profile cannot be unlinked.',
      );
    }
    final updated = RegisteredDevice(
      id: current.id,
      name: current.name,
      category: current.category,
      preferredProviderId: current.preferredProviderId == profile.providerId
          ? null
          : current.preferredProviderId,
      profiles: current.profiles.where(
        (candidate) => candidate.id != profile.id,
      ),
    );
    await _persist([
      ..._registered.map(
        (device) => device.id == current.id ? updated : device,
      ),
      _registry.fromProfile(profile.device),
    ]);
  });

  Future<void> forget(RemoteDevice device) => _write(() async {
    final current = logicalDevice(device.id);
    if (current == null) {
      await credentials.delete(device.id);
      return;
    }
    for (final profile in current.profiles) {
      await credentials.delete(profile.id);
    }
    await _persist(_registered.where((item) => item.id != current.id).toList());
  });

  Future<void> dispose() async {
    _closing = true;
    await _writes;
    devices.dispose();
  }
}
