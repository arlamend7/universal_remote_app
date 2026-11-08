import 'package:remote_core/remote_core.dart';

import '../../commands/services/lg_command_channel.dart';

final class LgChannelSelectionController {
  LgChannelSelectionController(this.channel);
  final LgCommandChannel channel;
  Future<List<DeviceChannel>> channels() async {
    final result = await channel.query('tv/getChannelList');
    final channels = result['channelList'];
    if (channels is! List) {
      throw const RemoteException(
        'channels',
        'The TV did not report a channel list.',
      );
    }
    return channels
        .whereType<Map<String, dynamic>>()
        .where((item) => item['channelId'] is String)
        .map(
          (item) => DeviceChannel(
            item['channelId'] as String,
            item['channelName'] as String? ?? 'Channel',
            item['channelNumber'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<void> selectChannel(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('Choose a reported channel.');
    }
    await channel.send(
      RemoteCapability.channelSelection,
      'tv/openChannel',
      payload: {'channelId': id},
    );
  }
}
