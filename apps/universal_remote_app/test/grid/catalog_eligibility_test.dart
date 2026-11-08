import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/muted_remote_panel.dart';

const _structural = {
  'group',
  'spacer',
  'unknown',
  'previous',
  'next',
  'seek',
  'artwork',
};

void main() {
  test('catalog distinguishes volume feedback from write controls and uses device capabilities', () {
    const capabilities = {RemoteCapability.volume};
    final adjustment = RemoteItemRegistry.resolve('volumeUp');
    final level = RemoteItemRegistry.resolve('volumeLevel');
    final group = RemoteItemRegistry.resolve('group');
    final rocker = RemoteItemRegistry.resolve('volumeDisplayRocker');
    final temperature = RemoteItemRegistry.resolve('targetTemperature');

    expect(
      RemoteItemRegistry.resolve(temperature.id),
      isA<RemoteItemDefinition<ACRemoteBase>>(),
    );
    expect(
      RemoteItemRegistry.resolve(adjustment.id),
      isA<RemoteItemDefinition<TvRemoteDevice>>(),
    );
    expect(
      RemoteItemRegistry.resolve(group.id),
      isA<RemoteItemDefinition<RemotePanel>>(),
    );
    expect(rocker.category, RemoteItemCategory.volume);
    expect(rocker.requires, {
      RemoteCapability.volume,
      RemoteCapability.volumeFeedback,
    });
    expect(rocker.elements.map((element) => element.id), [
      'volume_up',
      'current_volume',
      'volume_down',
    ]);
    expect(temperature.isCompatibleWith({RemoteCapability.climate}), isTrue);
    expect(temperature.isCompatibleWith(capabilities), isFalse);
    expect(adjustment.isCompatibleWith(capabilities), isTrue);
    expect(level.isCompatibleWith(capabilities), isFalse);
    expect(group.isCompatibleWith({}), isTrue);
    expect(level.isCompatibleWith({RemoteCapability.volumeFeedback}), isTrue);
  });

  test(
    'the horizontal volume slider takes two slots beside a one-slot level',
    () {
      final slider = RemoteItemRegistry.resolve('volumeSlider');
      expect(slider.elements.map((element) => element.id), [
        'current_volume',
        'volume_slider',
      ]);
      expect(slider.elements.map((element) => element.slots), [1, 2]);
      expect((slider.width, slider.height), (3, 1));
      final vertical = RemoteItemRegistry.resolve('volumeVerticalSlider');
      expect((vertical.width, vertical.height), (1, 3));
    },
  );

  test('wake is shared and requires wake support separately from power', () {
    final wake = RemoteItemRegistry.resolve('wake');
    expect(wake, isA<RemoteItemDefinition<RemotePanel>>());
    expect(wake.isCompatibleWith({RemoteCapability.wake}), isTrue);
    expect(wake.isCompatibleWith({RemoteCapability.power}), isFalse);
  });

  test('optional controls require their own provider capability', () {
    const controls = {
      'voice': RemoteCapability.voice,
      'gameMode': RemoteCapability.gameMode,
      'watch': RemoteCapability.watch,
    };
    for (final entry in controls.entries) {
      final definition = RemoteItemRegistry.resolve(entry.key);
      expect(definition.elements.single, isA<RemoteAction<TvRemoteDevice>>());
      expect(definition.isCompatibleWith({RemoteCapability.power}), isFalse);
      expect(definition.isCompatibleWith({entry.value}), isTrue);
    }
  });

  test('every registered element has an icon or resolves one', () {
    for (final definition in RemoteItemRegistry.definitions) {
      if (_structural.contains(definition.id) || definition.id == 'keypad') {
        continue;
      }
      expect(definition.elements, isNotEmpty, reason: definition.id);
      expect(
        definition.elements.every(
          (element) => element is RemoteAction || element.icon != null,
        ),
        isTrue,
        reason: definition.id,
      );
    }
  });

  test(
    'mute toggle icons follow device state and fixed actions stay explicit',
    () {
      IconData? icon(String definitionId, bool muted) {
        final panel = MutedRemotePanel(muted: muted);
        return GridRemoteViewModel(panel)
            .resolve(
              RemoteItemRegistry.resolve(definitionId).elements.single
                  as RemoteAction<Object>,
              RemoteElementContext(remote: panel),
            )!
            .icon;
      }

      expect(icon('mute', false), Icons.volume_off_outlined);
      expect(icon('mute', true), Icons.volume_up_outlined);
      expect(icon('muteOn', true), Icons.volume_off_outlined);
      expect(icon('muteOff', false), Icons.volume_up_outlined);
    },
  );

  test('current input is a readout with its own capability', () {
    final input = RemoteItemRegistry.resolve('currentInput');
    expect(input.elements.single, isA<RemoteInfo<TvRemoteDevice>>());
    expect((input.width, input.height), (2, 1));
    expect(input.isCompatibleWith({RemoteCapability.inputs}), isFalse);
    expect(input.isCompatibleWith({RemoteCapability.currentInput}), isTrue);
  });
  test('relative volume does not offer absolute volume or mute controls', () {
    const relative = {RemoteCapability.volume};
    expect(
      RemoteItemRegistry.resolve('volumeUp').isCompatibleWith(relative),
      isTrue,
    );
    for (final id in [
      'volumePreset',
      'volumeSlider',
      'volumeDial',
      'mute',
      'muteOn',
      'muteOff',
    ]) {
      expect(
        RemoteItemRegistry.resolve(id).isCompatibleWith(relative),
        isFalse,
        reason: id,
      );
    }
  });
}
