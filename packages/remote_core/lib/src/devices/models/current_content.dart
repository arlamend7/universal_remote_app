/// Only information actually reported by the device, never inferred playback.
final class CurrentContent {
  const CurrentContent({
    required this.appId,
    this.appName,
    this.channelName,
    this.channelNumber,
    this.liveTv = false,
    this.programTitle,
    this.position,
    this.duration,
  });
  final String appId;
  final String? appName;
  final String? channelName;
  final String? channelNumber;
  final bool liveTv;
  final String? programTitle;
  final Duration? position;
  final Duration? duration;

  /// Whether the integration reported live TV (tuner) content.
  bool get isLiveTv => liveTv;
}
