/// Operation kinds executed by the Samsung secure channel engine.
abstract final class SamsungChannelKinds {
  static const key = 'samsung-channel.key';
  static const launch = 'samsung-channel.launch';
  static const applications = 'samsung-channel.applications';

  static const all = {key, launch, applications};
}
