import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import 'package:universal_remote_app/app/app_bootstrap.dart';
import 'package:universal_remote_app/presentation/views/remote/viewmodels/remote_viewmodel.dart';

import '../support/fake_controller.dart';
import '../support/fake_provider.dart';
import '../support/memory_storage.dart';
import '../support/test_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
      containsAll(['directionPad', 'arrowPad', 'up', 'left', 'ok']),
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
    final sent = <MediaAction>[];
    final model = await _mediaModel(sent);
    final context = RemoteElementContext(remote: model.remote);
    ResolvedAction resolve() => TvItems.playPause.builder(context, model);
    expect(resolve().label, 'Play');
    await resolve().execute();
    expect(resolve().label, 'Pause');
    await resolve().execute();
    expect(resolve().label, 'Play');
    expect(sent, [MediaAction.play, MediaAction.pause]);
  });

  test('play and stop toggle alternates play and stop', () async {
    final sent = <MediaAction>[];
    final model = await _mediaModel(sent);
    final context = RemoteElementContext(remote: model.remote);
    ResolvedAction resolve() => TvItems.playStop.builder(context, model);
    expect(resolve().label, 'Play');
    await resolve().execute();
    expect(resolve().label, 'Stop');
    await resolve().execute();
    expect(sent, [MediaAction.play, MediaAction.stop]);
  });
}

Future<GridRemoteViewModel> _mediaModel(List<MediaAction> sent) async {
  final registry = ProviderRegistry()
    ..registerDefinition(
      ProviderDefinition(
        identifier: FakeProvider(),
        createController: (device) =>
            FakeController(device, enabledControls: true, mediaCommands: sent),
      ),
    );
  final app = await AppBootstrap.initialize(
    storage: MemoryStorage(),
    registry: registry,
  );
  addTearDown(app.dispose);
  await app.connection.connect(tv);
  return GridRemoteViewModel(RemoteViewModel(app));
}
