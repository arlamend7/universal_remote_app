final class TouchpadConfiguration {
  const TouchpadConfiguration({this.sensitivity = 1, this.scroll = true});

  factory TouchpadConfiguration.fromSettings(Map<String, String> settings) {
    final parsed = double.tryParse(settings['sensitivity'] ?? '');
    return TouchpadConfiguration(
      sensitivity: parsed == null || !parsed.isFinite ? 1 : parsed.clamp(.5, 2),
      scroll: settings['twoFingerScroll'] != 'false',
    );
  }

  final double sensitivity;
  final bool scroll;

  Map<String, String> toSettings() => {
    'sensitivity': '$sensitivity',
    'twoFingerScroll': '$scroll',
  };
}
