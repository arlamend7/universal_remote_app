import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/src/adapters/lg_webos/commands/services/lg_command_channel.dart';

final class LgInputController {
  LgInputController(this.channel);
  final LgCommandChannel channel;
  Future<List<DeviceInput>> inputs() async {
    final response = await channel.send(
      RemoteCapability.inputs,
      'tv/getExternalInputList',
    );
    final items = response['devices'];
    if (items is! List) {
      throw const RemoteException(
        'protocol',
        'The TV returned an invalid input list.',
      );
    }
    return items
        .whereType<Map<String, dynamic>>()
        .where((input) => input['id'] is String && input['label'] is String)
        .map(
          (input) =>
              DeviceInput(input['id'] as String, input['label'] as String),
        )
        .toList();
  }

  Future<void> selectInput(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Input ID is required.');
    }
    await channel.send(
      RemoteCapability.inputs,
      'tv/switchInput',
      payload: {'inputId': id},
    );
  }
}
