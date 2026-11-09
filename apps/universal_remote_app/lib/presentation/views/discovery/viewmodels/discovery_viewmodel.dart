import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../domains/discovery/functions/discovery_diagnostic_fields.dart';
import '../../../../domains/discovery/functions/discovery_failure_message.dart';

final class DiscoveryViewModel extends ChangeNotifier {
  DiscoveryViewModel(this.dependencies) {
    dependencies.discovery.devices.addListener(notifyListeners);
    dependencies.discovery.unresolved.addListener(notifyListeners);
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
  Iterable<ProtocolDiscoveryStatus> get statuses =>
      dependencies.discovery.statuses.value.values;
  String searchLabel(ProtocolDiscoveryStatus report) {
    if (report.protocolId == DiscoveryProtocol.unicast) {
      return '${report.provider.label} · Direct IP';
    }
    return switch (report.provider) {
      ProviderIdentity.custom => switch (report.protocolId) {
        DiscoveryProtocol.ssdp => 'SSDP',
        DiscoveryProtocol.bonjour => 'Bonjour',
        DiscoveryProtocol.unicast => 'Direct IP',
      },
      final provider => provider.label,
    };
  }

  List<String> get searchingProtocols => statuses
      .where((status) => status.status == DiscoveryStatus.searching)
      .map(searchLabel)
      .toList();
  String get diagnosticReport => const JsonEncoder.withIndent('  ').convert({
    'searchId': dependencies.discovery.searchId,
    'protocols': [
      for (final status in statuses)
        {
          ...discoveryDiagnosticFields(status),
          if (status.failure case final failure?)
            'remedy': discoveryFailureMessage(failure.error),
        },
    ],
  });
  int get unresolvedCount => dependencies.discovery.unresolved.value.length;
  List<RemoteDevice> get found => dependencies.discovery.devices.value;
  late final profiles = DiscoveryProfiles(
    profiles: () => dependencies.savedDevices.registered.expand(
      (device) => device.profiles.map(
        (profile) => copyDevice(profile.device, name: device.name),
      ),
    ),
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
      if (dependencies.savedDevices.byId(candidate.id) != null) {
        saveError = 'This result conflicts with a saved device. Verify the TV and edit its address in Devices.';
        return null;
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
    dependencies.discovery.unresolved.removeListener(notifyListeners);
    dependencies.discovery.busy.removeListener(notifyListeners);
    dependencies.discovery.error.removeListener(notifyListeners);
    dependencies.discovery.statuses.removeListener(notifyListeners);
    dependencies.savedDevices.devices.removeListener(notifyListeners);
    super.dispose();
  }
}
