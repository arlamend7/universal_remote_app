import 'package:remote_core/remote_core.dart';

import '../../commands/services/lg_command_channel.dart';

final class LgChannelController {
  LgChannelController(this.channel);
  final LgCommandChannel channel;
  Future<void> channelUp() async {
    await channel.send(RemoteCapability.channels, 'tv/channelUp');
  }

  Future<void> channelDown() async {
    await channel.send(RemoteCapability.channels, 'tv/channelDown');
  }
}
