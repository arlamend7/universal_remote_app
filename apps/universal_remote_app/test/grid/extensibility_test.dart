import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

import '../support/no_controller_panel_session.dart';

/// Only what these definitions read; every other member is unsupported.
final class _Panel implements RemotePanel {
  @override
  RemotePanelSession get connection => const NoControllerPanelSession();

  @override
  bool get ready => true;
  @override
  bool get offline => false;
  @override
  bool supports(RemoteCapability capability) => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not part of this fake',
  );
}

GridItem _item(String definitionId, [Map<String, String> config = const {}]) =>
    GridItem(
      id: 'x',
      definitionId: definitionId,
      x: 0,
      y: 0,
      w: 3,
      h: 1,
      config: config,
    );

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SizedBox(width: 360, height: 96, child: child)),
  ),
);

void main() {
  // New controls are declared once, as typed definitions. Nothing below edits
  // a renderer, a switch on String, or the registry.
  testWidgets('a new action and a new info render from their definition', (
    tester,
  ) async {
    final pressed = <String>[];
    final definition = RemoteItemDefinition<RemotePanel>(
      'spacer',
      'Demo',
      RemoteItemCategory.utilities,
      elements: [
        RemoteInfo<RemotePanel>(
          'demo_info',
          read: (_) => const RemoteReading('Hello info'),
        ),
        RemoteAction<RemotePanel>(
          'demo_action',
          builder: (context, remote) => (
            icon: Icons.star,
            label: 'Do it',
            enabled: true,
            execute: () async => pressed.add('pressed'),
          ),
        ),
      ],
    );
    final model = GridRemoteViewModel(_Panel());
    await _pump(
      tester,
      ElementStrip(definition: definition, item: _item('spacer'), model: model),
    );
    expect(find.text('Hello info'), findsOneWidget);
    await tester.tap(find.byTooltip('Do it'));
    await tester.pump();
    expect(pressed, ['pressed']);
  });

  testWidgets('two readings update independently', (tester) async {
    final first = StreamController<RemoteReading>();
    final second = StreamController<RemoteReading>();
    addTearDown(first.close);
    addTearDown(second.close);
    final definition = RemoteItemDefinition<RemotePanel>(
      'spacer',
      'Readings',
      RemoteItemCategory.information,
      elements: [
        RemoteInfo<RemotePanel>(
          'first',
          read: (_) => const RemoteReading('First'),
          watch: (_) => first.stream,
        ),
        RemoteInfo<RemotePanel>(
          'second',
          read: (_) => const RemoteReading('Second'),
          watch: (_) => second.stream,
        ),
      ],
    );
    await _pump(
      tester,
      ElementStrip(
        definition: definition,
        item: _item('spacer'),
        model: GridRemoteViewModel(_Panel()),
      ),
    );
    first.add(const RemoteReading('First update'));
    second.add(const RemoteReading('Second update'));
    await tester.pump();
    expect(find.text('First update'), findsOneWidget);
    expect(find.text('Second update'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('numeric controls bind a non-TV target and use its range', (
    tester,
  ) async {
    final commands = <double>[];
    final input = RemoteInput<RemotePanel, double>(
      'numeric',
      current: (_) => 19,
      minimum: 16,
      maximum: 24,
      step: 0.5,
      commit: (_, value) async => commands.add(value),
    );
    final definition = RemoteItemDefinition<RemotePanel>(
      'spacer',
      'Numeric',
      RemoteItemCategory.climate,
      elements: [input],
    );
    await _pump(
      tester,
      ElementStrip(
        definition: definition,
        item: _item('spacer'),
        model: GridRemoteViewModel(_Panel()),
      ),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect((slider.min, slider.max, slider.divisions), (16, 24, 16));
    slider.onChangeEnd!(21.5);
    await tester.pump();
    expect(commands, [21.5]);
  });

  testWidgets('a new collection reuses the collection renderer', (
    tester,
  ) async {
    final chosen = <String>[];
    final definition = RemoteItemDefinition<TvRemoteDevice>(
      'spacer',
      'Demo list',
      RemoteItemCategory.utilities,
      layout: const CollectionLayout(CollectionPresentation.strip),
      elements: [
        RemoteCollection<TvRemoteDevice, String>(
          'demo_collection',
          title: 'Demo',
          icon: (_) => Icons.star,
          load: (_) async => ['a', 'b'],
          entryId: (entry) => entry,
          entryName: (entry) => 'Entry $entry',
          fromOption: (id, name) => id,
          sample: (_) => const [],
          onSelected: (_, entry) async => chosen.add(entry),
        ),
      ],
    );
    final item = _item('spacer', {
      'targets': jsonEncode([
        {'id': 'a', 'name': 'Entry a'},
      ]),
    });
    await _pump(
      tester,
      CollectionView(
        definition: definition,
        item: item,
        model: GridRemoteViewModel(_Panel()),
      ),
    );
    await tester.tap(find.byTooltip('Entry a'));
    await tester.pump();
    expect(chosen, ['a']);
  });
}
