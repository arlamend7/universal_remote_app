import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../domains/discovery/functions/discovery_diagnostic_fields.dart';
import '../../../../domains/discovery/functions/discovery_failure_message.dart';

final class DiscoveryViewModel extends ChangeNotifier {
  DiscoveryViewModel(this.dependencies) {
    dependencies.discovery.devices.addListener(notifyListeners);
    dependencies.discovery.busy.addListener(notifyListeners);
    dependencies.discovery.error.addListener(notifyListeners);
    dependencies.discovery.statuses.addListener(notifyListeners);
    dependencies.savedDevices.devices.addListener(notifyListeners);
  }
  final AppDependencies dependencies;
  bool adding = false;
  String? saveError;
  bool get cancelled => dependencies.discovery.cancelled;
  bool get searching => dependencies.discovery.busy.value;
  String? get error => saveError ?? dependencies.discovery.error.value;
  Iterable<ProviderDiscoveryStatus> get statuses =>
      dependencies.discovery.statuses.value.values;
  String providerLabel(String id) =>
      dependencies.providers.manualSetups[id]?.label ?? id;
  List<String> get searchingProviders => statuses
      .where((status) => status.status == DiscoveryStatus.searching)
      .map((status) => providerLabel(status.providerId))
      .toList();
  String get diagnosticReport => const JsonEncoder.withIndent('  ').convert({
    'searchId': dependencies.discovery.searchId,
    'providers': [
      for (final status in statuses)
        {
          ...discoveryDiagnosticFields(status),
          if (status.failure case final failure?)
            'remedy': discoveryFailureMessage(failure.error),
        },
    ],
  });
  List<RemoteDevice> get found =>
      DeviceIdentity.unique(dependencies.discovery.devices.value);
  late final profiles = DiscoveryProfiles(
    profiles: () => dependencies.savedDevices.devices.value,
    update: dependencies.savedDevices.updateExisting,
  );
  RemoteDevice? registered(RemoteDevice candidate) =>
      profiles.registered(candidate);
  List<RemoteDevice> get fresh =>
      found.where((item) => registered(item) == null).toList();
  List<RemoteDevice> get known =>
      found.where((item) => registered(item) != null).toList();
  Future<void> search() async {
    saveError = null;
    await dependencies.discovery.search();
    if (_disposed) {
      return;
    }
    try {
      await _rememberIdentities();
    } catch (_) {
      if (!_disposed) {
        saveError =
            'Devices were found, but their identities could not be saved.';
        notifyListeners();
      }
    }
  }

  Future<void> _rememberIdentities() async {
    for (final candidate in found) {
      if (_disposed) {
        return;
      }
      await profiles.remember(candidate);
    }
  }

  void cancel() => dependencies.discovery.cancel();
  Future<RemoteDevice?> add(RemoteDevice candidate) async {
    if (adding) {
      return null;
    }
    adding = true;
    saveError = null;
    notifyListeners();
    try {
      final existing = registered(candidate);
      if (existing != null) {
        return existing;
      }
      await dependencies.savedDevices.save(candidate);
      return candidate;
    } catch (_) {
      saveError = 'Could not add this device. Please retry.';
      return null;
    } finally {
      adding = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> updateAddress(RemoteDevice candidate) async {
    final existing = registered(candidate);
    if (existing == null || adding) {
      return;
    }
    adding = true;
    saveError = null;
    notifyListeners();
    try {
      await profiles.updateAddress(candidate);
    } catch (_) {
      saveError = 'Could not update the address. Please retry.';
    } finally {
      adding = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    cancel();
    dependencies.discovery.devices.removeListener(notifyListeners);
    dependencies.discovery.busy.removeListener(notifyListeners);
    dependencies.discovery.error.removeListener(notifyListeners);
    dependencies.discovery.statuses.removeListener(notifyListeners);
    dependencies.savedDevices.devices.removeListener(notifyListeners);
    super.dispose();
  }
}
