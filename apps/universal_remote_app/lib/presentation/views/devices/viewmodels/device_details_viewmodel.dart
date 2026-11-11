import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';

import 'package:remote_ui/remote_ui.dart';

import '../../../../routes/open_remote_editor.dart';
import '../modals/edit_device.dart';

final class DeviceDetailsViewModel {
  DeviceDetailsViewModel(this.dependencies, this.original);
  final AppDependencies dependencies;
  final RemoteDevice original;
  RemoteDevice get device =>
      dependencies.savedDevices.byId(original.id) ?? original;
  DeviceSoftwareInformation? get liveSoftware {
    final controller = dependencies.connection.controller;
    if (!connected || controller?.device.id != device.id) {
      return null;
    }
    return controller?.sessionSoftwareInformation;
  }

  String get wakeStatus {
    if (!dependencies.providers.canWake(device)) {
      return 'Not configured';
    }
    return DeviceWakeLearner.wasLearned(device)
        ? 'Address detected automatically'
        : 'Address configured';
  }

  bool get selected {
    final selected = dependencies.connection.selected.value?.id;
    return selected == device.id ||
        dependencies.savedDevices
                .logicalDevice(device.id)
                ?.profiles
                .any((profile) => profile.id == selected) ==
            true;
  }

  bool get connected =>
      selected &&
      dependencies.connection.state.value == DeviceConnectionState.connected;
  Listenable get changes => Listenable.merge([
    dependencies.savedDevices.devices,
    dependencies.connection.state,
    dependencies.connection.selected,
    dependencies.connection.currentContent,
    dependencies.connection.revision,
  ]);
  List<CapabilityEvidence> get evidence =>
      selected ? dependencies.connection.controller?.evidence ?? [] : [];
  String? get currentApp =>
      connected ? dependencies.connection.currentContent.value?.appName : null;
  RegisteredDevice? get _logical =>
      dependencies.savedDevices.logicalDevice(original.id);
  List<ConnectionProfile> get _profiles =>
      _logical?.profiles.where((profile) => profile.confirmed).toList() ?? [];
  bool get canChooseProvider =>
      _profiles.map((profile) => profile.providerId).toSet().length > 1;
  bool get canLink =>
      dependencies.savedDevices.associationCandidates(original.id).isNotEmpty;
  bool get canUnlink => _profiles.any((profile) => profile.userAssociated);

  String _providerLabel(String id) =>
      dependencies.providers.manualSetups[id]?.label ?? id;

  Future<void> chooseProvider(BuildContext context) async {
    final provider = await DeviceChoiceSheet.choose(
      context,
      'Preferred integration',
      [
        for (final profile in _profiles)
          (profile.providerId, _providerLabel(profile.providerId)),
      ],
      selectedId: _logical?.preferredProfile.providerId,
    );
    if (provider != null && context.mounted) {
      await _protect(
        context,
        () => dependencies.savedDevices.preferProvider(original.id, provider),
      );
    }
  }

  Future<void> linkProfile(BuildContext context) async {
    final candidate = await DeviceChoiceSheet.choose(
      context,
      'Select the same physical device',
      [
        for (final other in dependencies.savedDevices.associationCandidates(
          original.id,
        ))
          (
            other.id,
            '${other.name} · ${_providerLabel(other.preferredProfile.providerId)}',
          ),
      ],
    );
    if (candidate == null || !context.mounted) {
      return;
    }
    final confirmed = await ConfirmationDialog.ask(
      context,
      title: 'Link these profiles?',
      confirmLabel: 'Link profiles',
      message: 'Confirm both profiles control the same physical device. You can unlink them later.',
    );
    if (confirmed && context.mounted) {
      await _protect(
        context,
        () => dependencies.savedDevices.associate(original.id, candidate),
      );
    }
  }

  Future<void> unlinkProfile(BuildContext context) async {
    final profileId = await DeviceChoiceSheet.choose(
      context,
      'Unlink integration',
      [
        for (final profile in _profiles.where(
          (profile) => profile.userAssociated,
        ))
          (profile.id, _providerLabel(profile.providerId)),
      ],
    );
    if (profileId != null && context.mounted) {
      await _protect(
        context,
        () => dependencies.savedDevices.detach(original.id, profileId),
      );
    }
  }

  Future<void> customize(BuildContext context) =>
      openRemoteEditor(context, dependencies, device);
  Future<void> edit(BuildContext context) async {
    final edited = await editDevice(context, dependencies, device: device);
    if (edited == null || !context.mounted) {
      return;
    }
    await _protect(context, () async {
      await dependencies.savedDevices.save(edited);
      if (edited.name != device.name) {
        await dependencies.savedDevices.rename(edited, edited.name);
      }
      if (selected) {
        await dependencies.connection.connect(edited);
      }
    });
  }

  Future<void> rePair(BuildContext context) async {
    final confirmed = await ConfirmationDialog.ask(
      context,
      title: 'Pair ${device.name} again?',
      confirmLabel: 'Re-pair',
      message: 'You will need to approve the connection on your TV.',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await _protect(context, () async {
      if (selected) {
        await dependencies.connection.rePair();
        return;
      }
      await dependencies.savedDevices.credentials.delete(device.id);
      await dependencies.connection.connect(device);
    });
  }

  Future<void> disconnect(BuildContext context) =>
      _protect(context, dependencies.connection.disconnect);
  Future<void> _protect(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this change. Please retry.'),
          ),
        );
      }
    }
  }
}
