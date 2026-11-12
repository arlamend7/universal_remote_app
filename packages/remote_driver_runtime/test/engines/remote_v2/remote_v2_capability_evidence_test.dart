import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

import 'support/paired_android_tv.dart';

/// Remote v2 feature bits (documented): PING 1, KEY 2, IME 4, POWER 32,
/// VOLUME 64, APP_LINK 512. Audio mode 2 = absolute, 1 = adjustable.
const _ping = 1, _key = 2, _ime = 4, _power = 32, _volume = 64, _app = 512;
const _all = _ping | _key | _ime | _power | _volume | _app;

Future<Set<RemoteCapability>> _supported({
  required int features,
  int? audioMode = 2,
  Map<int, Object>? deviceInfo,
}) async {
  final tv = await pairedAndroidTv(
    features: features,
    audioMode: audioMode,
    deviceInfo: deviceInfo,
  );
  await tv.remote.connect();
  return {
    for (final capability in RemoteCapability.values)
      if (tv.remote.supports(capability)) capability,
  };
}

const _keyCapabilities = {
  RemoteCapability.navigation,
  RemoteCapability.media,
  RemoteCapability.numericKeys,
  RemoteCapability.tvSettings,
  RemoteCapability.specialKeys,
  RemoteCapability.trackNavigation,
  RemoteCapability.liveTvKey,
  RemoteCapability.captionsKey,
  RemoteCapability.inputs,
  RemoteCapability.channels,
  RemoteCapability.volume,
};

void main() {
  test('everything negotiated with an absolute output', () async {
    final supported = await _supported(features: _all);
    expect(supported, containsAll(_keyCapabilities));
    expect(
      supported,
      containsAll({
        RemoteCapability.textInput,
        RemoteCapability.currentContent,
        RemoteCapability.applications,
        RemoteCapability.power,
        RemoteCapability.mute,
        RemoteCapability.absoluteVolume,
        RemoteCapability.volumeFeedback,
      }),
    );
  });

  test('keys only: no text, apps, power or audio claims', () async {
    final supported = await _supported(features: _ping | _key, audioMode: null);
    expect(supported, containsAll(_keyCapabilities));
    for (final capability in [
      RemoteCapability.textInput,
      RemoteCapability.currentContent,
      RemoteCapability.applications,
      RemoteCapability.power,
      RemoteCapability.absoluteVolume,
      RemoteCapability.volumeFeedback,
    ]) {
      expect(supported, isNot(contains(capability)), reason: '$capability');
    }
  });

  test('no keys feature: no key-driven controls at all', () async {
    final supported = await _supported(features: _ping | _ime | _app);
    expect(supported.intersection(_keyCapabilities), isEmpty);
    expect(supported, isNot(contains(RemoteCapability.power)));
    expect(supported, contains(RemoteCapability.textInput));
    expect(supported, contains(RemoteCapability.applications));
  });

  test('missing POWER or APP_LINK removes only that control', () async {
    final noPower = await _supported(features: _all & ~_power);
    expect(noPower, isNot(contains(RemoteCapability.power)));
    expect(noPower, contains(RemoteCapability.applications));
    final noApps = await _supported(features: _all & ~_app);
    expect(noApps, isNot(contains(RemoteCapability.applications)));
    expect(noApps, contains(RemoteCapability.power));
  });

  test('without VOLUME, audio reports are ignored', () async {
    final supported = await _supported(features: _all & ~_volume);
    expect(supported, contains(RemoteCapability.volume));
    expect(supported, isNot(contains(RemoteCapability.volumeFeedback)));
    expect(supported, isNot(contains(RemoteCapability.absoluteVolume)));
  });

  test('an adjustable output reports volume but no exact level', () async {
    final supported = await _supported(features: _all, audioMode: 1);
    expect(supported, contains(RemoteCapability.volumeFeedback));
    expect(supported, isNot(contains(RemoteCapability.absoluteVolume)));
  });

  test('the reported vendor never changes the available controls', () async {
    Future<Set<RemoteCapability>> as(String vendor) => _supported(
      features: _all & ~_power,
      audioMode: 1,
      deviceInfo: {1: 'Model', 2: vendor},
    );
    final tcl = await as('TCL');
    expect(await as('Google'), tcl);
    expect(await as('Sony'), tcl);
  });

  test('a TCL-reporting TV receives the same key codes', () async {
    final tv = await pairedAndroidTv(deviceInfo: {1: 'Smart TV Pro', 2: 'TCL'});
    await tv.remote.connect();
    tv.recorder.drain();
    await tv.remote.press(NavigationKey.up);
    await tv.remote.channelUp();
    await tv.remote.sendMedia(MediaAction.play);
    await tv.remote.volumeUp();
    await tv.remote.sendKey(RemoteKey.guide);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final codes = [
      for (final frame in tv.recorder.drain())
        if (frame case {'remoteV2': {'10': {'1': final int code}}}) code,
    ];
    expect(codes, [19, 166, 126, 24, 172]);
  });
}
