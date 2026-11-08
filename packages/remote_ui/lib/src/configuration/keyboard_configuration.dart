final class KeyboardConfiguration {
  const KeyboardConfiguration({this.submitAfterTyping = false});

  factory KeyboardConfiguration.fromSettings(Map<String, String> settings) =>
      KeyboardConfiguration(
        submitAfterTyping: settings['submitAfterTyping'] == 'true',
      );

  final bool submitAfterTyping;

  Map<String, String> toSettings() => {
    'submitAfterTyping': '$submitAfterTyping',
  };
}
