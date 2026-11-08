import '../layout/models/enums/grid_widget_kind.dart';
import '../layout/models/grid_item.dart';
import '../layout/models/grid_layout.dart';

/// One starter dashboard, used by both the remote and the editor.
GridLayout defaultRemoteGrid() => GridLayout([
  _item(GridWidgetKind.currentActivity, 0, 0, 4, 1),
  _item(GridWidgetKind.directionPad, 0, 1, 4, 3),
  _item(GridWidgetKind.navigationStrip, 0, 4, 2, 1),
  _item(GridWidgetKind.channelRocker, 2, 4, 2, 2),
  _item(GridWidgetKind.volumeHorizontal, 0, 5, 2, 1),
  _item(GridWidgetKind.apps, 0, 6, 2, 1),
  _item(GridWidgetKind.inputs, 2, 6, 2, 1),
  _item(GridWidgetKind.volumeSlider, 0, 7, 4, 1),
  _item(GridWidgetKind.keyboard, 0, 8, 4, 1),
  _item(GridWidgetKind.mute, 0, 9, 4, 1),
]);

GridItem _item(GridWidgetKind kind, int x, int y, int w, int h) =>
    GridItem(id: 'default-${kind.name}', kind: kind, x: x, y: y, w: w, h: h);
