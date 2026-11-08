import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

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
}
