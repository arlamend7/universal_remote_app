import 'package:remote_core/remote_core.dart';

import '../../commands/services/lg_command_channel.dart';

final class LgMediaController {
  LgMediaController(this.channel);
  final LgCommandChannel channel;
  Future<void> send(MediaAction action) async {
    await channel.send(RemoteCapability.media, 'media.controls/${action.name}');
  }
}
