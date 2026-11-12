import 'package:remote_core/remote_core.dart';

/// Editor-only examples. Never saved as TV state or used by the live remote.
final class RemotePreviewData {
  const RemotePreviewData();
  static const example = RemotePreviewData();
  VolumeState get volume => const VolumeState(35, false);
  CurrentContent get content => const CurrentContent(
    appId: 'com.webos.app.livetv',
    liveTv: true,
    appName: 'Live TV',
    channelNumber: '42',
    channelName: 'National Geographic HD',
  );
  List<(String, String)> get applications => const [
    ('sample.netflix', 'Netflix'),
    ('sample.youtube', 'YouTube'),
    ('sample.disney', 'Disney+'),
  ];
  List<(String, String)> get inputs => const [
    ('sample.hdmi1', 'HDMI 1'),
    ('sample.hdmi2', 'HDMI 2'),
  ];
  List<(String, String)> get channels => const [
    ('sample.channel42', 'National Geographic HD'),
    ('sample.channel7', 'BBC One HD'),
  ];
}
