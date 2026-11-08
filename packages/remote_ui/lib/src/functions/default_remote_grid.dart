import '../layout/models/grid_item.dart';
import '../layout/models/grid_layout.dart';

/// One starter dashboard, used by both the remote and the editor.
GridLayout defaultRemoteGrid() => GridLayout([
  _item('currentActivity', 0, 0, 4, 1),
  _item('directionPad', 0, 1, 4, 3),
  _item('navigationStrip', 0, 4, 2, 1),
  _item('channelRocker', 2, 4, 2, 2),
  _item('volumeHorizontal', 0, 5, 2, 1),
  _item('apps', 0, 6, 2, 1),
  _item('inputs', 2, 6, 2, 1),
  _item('volumeSlider', 0, 7, 4, 1),
  _item('keyboard', 0, 8, 4, 1),
  _item('mute', 0, 9, 4, 1),
]);

GridItem _item(String definitionId, int x, int y, int w, int h) => GridItem(
  id: 'default-${definitionId}',
  definitionId: definitionId,
  x: x,
  y: y,
  w: w,
  h: h,
);
