import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../../../app/app_dependencies.dart';

import 'package:remote_ui/remote_ui.dart';

import '../../../../routes/open_remote_editor.dart';
import '../modals/device_rename_sheet.dart';
import '../modals/edit_device.dart';

final class DeviceDetailsViewModel {
  DeviceDetailsViewModel(this.dependencies, this.original);
  final AppDependencies dependencies;
  final RemoteDevice original;
  RemoteDevice get device =>
      dependencies.savedDevices.byId(original.id) ?? original;
  String get wakeStatus {
    if (!dependencies.providers.canWake(device)) {
      return 'Not configured';
    }
    return DeviceWakeLearner.wasLearned(device)
        ? 'Address detected automatically'
        : 'Address configured';
  }

  bool get selected => dependencies.connection.selected.value?.id == device.id;
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
  Future<void> customize(BuildContext context) =>
      openRemoteEditor(context, dependencies, device);
  Future<void> edit(BuildContext context) async {
    final edited = await editDevice(context, dependencies, device: device);
    if (edited == null || !context.mounted) {
      return;
    }
    await _protect(context, () async {
      await dependencies.savedDevices.save(edited);
      if (selected) {
        await dependencies.connection.connect(edited);
      }
    });
  }

  Future<void> rename(BuildContext context) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => DeviceRenameSheet(name: device.name),
    );
    if (name == null || !context.mounted) {
      return;
    }
    await _protect(
      context,
      () => dependencies.savedDevices.rename(device, name),
    );
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
  Future<bool> forget(BuildContext context) async {
    final confirmed = await ConfirmationDialog.ask(
      context,
      title: 'Forget ${device.name}?',
      confirmLabel: 'Forget',
      message: 'Removes this TV, its layout and saved authorization.',
    );
    if (!confirmed || !context.mounted) {
      return false;
    }
    var removed = false;
    await _protect(context, () async {
      await dependencies.connection.forget(device);
      removed = true;
    });
    return removed;
  }

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
