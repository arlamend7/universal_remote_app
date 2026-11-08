import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/muted_remote_panel.dart';

void main() {
  test('every persisted definitionId resolves to one definition that owns its renderer', () {
    final ids = <String>{};
    for (final definition in RemoteItemRegistry.definitions) {
      expect(ids.add(definition.id), isTrue, reason: definition.id);
      expect(RemoteItemRegistry.resolve(definition.id), same(definition));
      expect(definition.name, isNotEmpty, reason: definition.id);
    }
    expect(
      RemoteItemRegistry.resolve('saved-by-a-newer-version').id,
      'unknown',
    );
  });

  test(
    'specialised layouts are declared by the definition, not by definitionId',
    () {
      RemoteItemLayout layout(String definitionId) =>
          RemoteItemRegistry.resolve(definitionId).layout;
      expect(layout('touchpad'), isA<TouchSurfaceLayout>());
      expect(layout('keypad'), isA<ElementGridLayout>());
      expect(layout('group'), isA<GroupLayout>());
      expect(layout('currentInput'), isA<LinearLayout>());
      expect(layout('channelGroup'), isA<CollectionLayout>());
      expect(layout('appGrid'), isA<CollectionLayout>());
      expect(layout('volumeDial'), isA<DialLayout>());
      expect(layout('seek'), isA<UnavailableLayout>());
      expect(layout('directionPad'), isA<DirectionPadLayout>());
    },
  );

  test('eligibility is decided once by the definition', () {
    final up = RemoteItemRegistry.resolve('volumeUp');
    expect(up.isCompatibleWith({RemoteCapability.volume}), isTrue);
    expect(up.isCompatibleWith({RemoteCapability.media}), isFalse);
    final unknown = RemoteItemRegistry.resolve('unknown');
    expect(unknown.isCompatibleWith(RemoteCapability.values.toSet()), isFalse);
  });

  test('styles are only offered between real alternatives of one control', () {
    List<String> styles(String id) =>
        RemoteItemRegistry.variations(id).map((item) => item.id).toList();
    expect(styles('touchpad'), ['touchpad']);
    expect(styles('deviceAddress'), ['deviceAddress']);
    expect(styles('keypad'), ['keypad']);
    expect(
      styles('transport'),
      containsAll(['transport', 'play', 'playPause', 'stop']),
    );
    expect(styles('transport'), isNot(contains('up')));
    expect(
      styles('up'),
      containsAll(['directionPad', 'crossPad', 'arrowPad', 'up', 'left', 'ok']),
    );
    expect(styles('up'), isNot(contains('home')));
    expect(styles('home'), containsAll(['home', 'back', 'apps', 'menu']));
    expect(styles('home'), isNot(contains('up')));
    expect(styles('home'), isNot(contains('ok')));
    expect(styles('volumeUp'), containsAll(['volumeUp', 'volumeRocker']));
    expect(styles('recentApps'), containsAll(['recentApps', 'appStrip']));
    expect(styles('currentActivity'), ['currentActivity', 'currentApp']);
    expect(styles('channelRocker'), ['channelRocker', 'channelDisplayRocker']);
    expect(styles('volumeDial'), contains('volumeRocker'));
    expect(styles('appGrid'), isNot(contains('inputGrid')));
  });

  test('text and gesture controls can be made smaller than their default', () {
    final activity = RemoteItemRegistry.resolve('currentActivity');
    expect((activity.width, activity.height), (4, 1));
    expect(activity.accepts(2, 1), isTrue);
    expect(RemoteItemRegistry.resolve('inputStrip').accepts(2, 1), isTrue);
    expect(RemoteItemRegistry.resolve('recentApps').accepts(2, 1), isTrue);
    expect(RemoteItemRegistry.resolve('touchpad').accepts(2, 2), isTrue);
    expect(RemoteItemRegistry.resolve('volumeExpanded').accepts(3, 2), isTrue);
    expect(RemoteItemRegistry.resolve('keyboard').accepts(1, 1), isTrue);
    expect(RemoteItemRegistry.resolve('sleep').accepts(1, 1), isTrue);
  });

  test('play and pause toggle alternates the command it sends', () async {
    final device = _MediaDevice();
    final panel = MutedRemotePanel(muted: false);
    final context = RemoteElementContext(remote: panel);
    ResolvedAction resolve() => TvItems.playPause.builder(context, device);
    expect(resolve().label, 'Play');
    await resolve().execute();
    expect(resolve().label, 'Pause');
    await resolve().execute();
    expect(resolve().label, 'Play');
    expect(device.sent, [MediaAction.play, MediaAction.pause]);
  });
}

final class _MediaDevice implements TvRemoteDevice {
  final sent = <MediaAction>[];
  @override
  bool get mediaPlaying => sent.lastOrNull == MediaAction.play;
  @override
  Future<void> togglePlayback() =>
      media(mediaPlaying ? MediaAction.pause : MediaAction.play);
  @override
  Future<void> media(MediaAction action) async => sent.add(action);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not part of this fake',
  );
}
