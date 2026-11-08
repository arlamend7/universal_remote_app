import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/muted_remote_panel.dart';

const _structural = {
  GridWidgetKind.group,
  GridWidgetKind.spacer,
  GridWidgetKind.unknown,
  GridWidgetKind.previous,
  GridWidgetKind.next,
  GridWidgetKind.seek,
  GridWidgetKind.artwork,
};

void main() {
  test('catalog distinguishes volume feedback from write controls and uses device capabilities', () {
    const capabilities = {RemoteCapability.volume};
    final adjustment = WidgetCatalog.definition(GridWidgetKind.volumeUp);
    final level = WidgetCatalog.definition(GridWidgetKind.volumeLevel);
    final group = WidgetCatalog.definition(GridWidgetKind.group);
    final rocker = RemoteItemRegistry.resolve(
      GridWidgetKind.volumeDisplayRocker,
    );
    final temperature = WidgetCatalog.definition(
      GridWidgetKind.targetTemperature,
    );

    expect(
      RemoteItemRegistry.resolve(temperature.kind),
      isA<RemoteItemDefinition<AcDeviceController>>(),
    );
    expect(
      RemoteItemRegistry.resolve(adjustment.kind),
      isA<RemoteItemDefinition<TvRemoteDevice>>(),
    );
    expect(
      RemoteItemRegistry.resolve(group.kind),
      isA<RemoteItemDefinition<RemotePanel>>(),
    );
    expect(rocker.category, RemoteItemCategory.audio);
    expect(rocker.requires, {RemoteCapability.volume});
    expect(rocker.elements.map((element) => element.id), [
      'volume_up',
      'current_volume',
      'volume_down',
    ]);
    expect(
      isCatalogCompatible(temperature, {RemoteCapability.climate}),
      isTrue,
    );
    expect(isCatalogCompatible(temperature, capabilities), isFalse);
    expect(isCatalogCompatible(adjustment, capabilities), isTrue);
    expect(isCatalogCompatible(level, capabilities), isFalse);
    expect(isCatalogCompatible(group, {}), isTrue);
    expect(
      isCatalogCompatible(level, {RemoteCapability.volumeFeedback}),
      isTrue,
    );
  });

  test(
    'the horizontal volume slider takes two slots beside a one-slot level',
    () {
      final slider = WidgetCatalog.definition(GridWidgetKind.volumeSlider);
      expect(slider.elements.map((element) => element.id), [
        'current_volume',
        'volume_slider',
      ]);
      expect(slider.elements.map((element) => element.slots), [1, 2]);
      expect((slider.width, slider.height), (3, 1));
      final vertical = WidgetCatalog.definition(
        GridWidgetKind.volumeVerticalSlider,
      );
      expect((vertical.width, vertical.height), (1, 3));
    },
  );

  test('wake is shared and requires wake support separately from power', () {
    final wake = WidgetCatalog.definition(GridWidgetKind.wake);
    expect(wake, isA<RemoteItemDefinition<RemotePanel>>());
    expect(isCatalogCompatible(wake, {RemoteCapability.wake}), isTrue);
    expect(isCatalogCompatible(wake, {RemoteCapability.power}), isFalse);
  });

  test('optional controls require their own provider capability', () {
    const controls = {
      GridWidgetKind.voice: RemoteCapability.voice,
      GridWidgetKind.gameMode: RemoteCapability.gameMode,
      GridWidgetKind.watch: RemoteCapability.watch,
    };
    for (final entry in controls.entries) {
      final definition = WidgetCatalog.definition(entry.key);
      expect(
        definition.elements.single,
        isA<RemoteAction<TvRemoteDevice, Null>>(),
      );
      expect(
        isCatalogCompatible(definition, {RemoteCapability.power}),
        isFalse,
      );
      expect(isCatalogCompatible(definition, {entry.value}), isTrue);
    }
  });

  test('every registered control has elements with icons', () {
    for (final definition in WidgetCatalog.definitions) {
      if (_structural.contains(definition.kind)) {
        continue;
      }
      expect(definition.elements, isNotEmpty, reason: definition.kind.name);
      expect(
        definition.elements.every((element) => element.icon != null),
        isTrue,
        reason: definition.kind.name,
      );
    }
  });

  test(
    'mute toggle icons follow device state and fixed actions stay explicit',
    () {
      IconData icon(GridWidgetKind kind, bool muted) =>
          WidgetCatalog.definition(kind).elements.single.icon!(
            RemoteElementContext(
              kind: kind,
              remote: MutedRemotePanel(muted: muted),
            ),
          );

      expect(icon(GridWidgetKind.mute, false), Icons.volume_off_outlined);
      expect(icon(GridWidgetKind.mute, true), Icons.volume_up_outlined);
      expect(icon(GridWidgetKind.muteOn, true), Icons.volume_off_outlined);
      expect(icon(GridWidgetKind.muteOff, false), Icons.volume_up_outlined);
    },
  );

  test('current input is a readout with its own capability', () {
    final input = WidgetCatalog.definition(GridWidgetKind.currentInput);
    expect(input.elements.single, isA<RemoteInfo<TvRemoteDevice>>());
    expect((input.width, input.height), (2, 1));
    expect(isCatalogCompatible(input, {RemoteCapability.inputs}), isFalse);
    expect(isCatalogCompatible(input, {RemoteCapability.currentInput}), isTrue);
  });
}
