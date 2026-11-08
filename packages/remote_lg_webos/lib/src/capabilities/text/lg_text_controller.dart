import 'package:remote_core/remote_core.dart';

import '../../commands/services/lg_command_channel.dart';

final class LgTextController {
  LgTextController(this.channel);
  final LgCommandChannel channel;
  Future<void> sendText(String text) async {
    if (text.isEmpty || text.length > 2048) {
      throw ArgumentError('Enter between 1 and 2048 characters.');
    }
    await channel.send(
      RemoteCapability.textInput,
      'com.webos.service.ime/insertText',
      payload: {'text': text, 'replace': 0},
    );
  }

  Future<void> enter() async {
    await channel.send(
      RemoteCapability.textInput,
      'com.webos.service.ime/sendEnterKey',
    );
  }
}
