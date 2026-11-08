import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:remote_ui/src/ui_model.dart';

import 'package:remote_core/remote_core.dart';

import '../viewmodels/grid_remote_viewmodel.dart';
import 'grid_button.dart';
import 'grid_unavailable.dart';

class GridNavigationWidget extends StatelessWidget {
  const GridNavigationWidget({
    super.key,
    required this.item,
    required this.model,
  });
  final GridItem item;
  final GridRemoteViewModel model;
  Widget _key(NavigationKey key, String label, IconData icon) => GridButton(
    appearance: item.config,
    label: label,
    icon: icon,
    showLabel: false,
    repeat: item.config['hold'] == 'true',
    onPressed: model.remote.canNavigate
        ? () => item.element(TvItems.navigation).onPressed(model, key)
        : null,
  );
  @override
  Widget build(BuildContext context) => switch (item.kind) {
    GridWidgetKind.home => _key(
      NavigationKey.home,
      'Home',
      Icons.home_outlined,
    ),
    GridWidgetKind.back => _key(NavigationKey.back, 'Back', Icons.undo),
    GridWidgetKind.ok => _key(NavigationKey.enter, 'OK', Icons.check),
    GridWidgetKind.up => _key(NavigationKey.up, 'Up', Icons.keyboard_arrow_up),
    GridWidgetKind.down => _key(
      NavigationKey.down,
      'Down',
      Icons.keyboard_arrow_down,
    ),
    GridWidgetKind.left => _key(
      NavigationKey.left,
      'Left',
      Icons.keyboard_arrow_left,
    ),
    GridWidgetKind.right => _key(
      NavigationKey.right,
      'Right',
      Icons.keyboard_arrow_right,
    ),
    GridWidgetKind.navigationStrip => Row(
      children: [
        Expanded(child: _key(NavigationKey.home, 'Home', Icons.home_outlined)),
        Expanded(child: _key(NavigationKey.back, 'Back', Icons.undo)),
      ],
    ),
    _ => _pad(context),
  };
  Widget _pad(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final shortcuts = item.config['shortcuts'] == 'true';
      final side = math.min(
        constraints.maxWidth,
        constraints.maxHeight - (shortcuts ? 48 : 0),
      );
      if (side < 144) {
        return const GridUnavailable(
          title: 'Enlarge navigation',
          reason: 'Use at least three columns on this screen to preserve accessible direction targets.',
        );
      }
      return Column(
        children: [
          Expanded(child: Center(child: _ring(context, side))),
          if (shortcuts)
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _key(NavigationKey.home, 'Home', Icons.home_outlined),
                  _key(NavigationKey.back, 'Back', Icons.undo),
                ],
              ),
            ),
        ],
      );
    },
  );
  Widget _ring(BuildContext context, double side) => Container(
    width: side,
    height: side,
    decoration: BoxDecoration(
      shape: item.kind == GridWidgetKind.crossPad
          ? BoxShape.rectangle
          : BoxShape.circle,
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: .35),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox.square(
            dimension: 48,
            child: _key(NavigationKey.up, 'Up', Icons.keyboard_arrow_up),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox.square(
            dimension: 48,
            child: _key(NavigationKey.down, 'Down', Icons.keyboard_arrow_down),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(
            dimension: 48,
            child: _key(NavigationKey.left, 'Left', Icons.keyboard_arrow_left),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox.square(
            dimension: 48,
            child: _key(
              NavigationKey.right,
              'Right',
              Icons.keyboard_arrow_right,
            ),
          ),
        ),
        SizedBox.square(
          dimension: 48,
          child: TextButton(
            onPressed: model.remote.canNavigate
                ? () => item
                      .element(TvItems.navigation)
                      .onPressed(model, NavigationKey.enter)
                : null,
            child: const Text('OK'),
          ),
        ),
      ],
    ),
  );
}
