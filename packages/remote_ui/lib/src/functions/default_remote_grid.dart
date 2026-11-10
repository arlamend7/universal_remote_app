import '../layout/models/grid_item.dart';
import '../layout/models/grid_layout.dart';

/// One starter dashboard, used by both the remote and the editor.
GridLayout defaultRemoteGrid() => GridLayout([
  _item('currentActivity', 0, 0, 2, 1),
  _item('navigationStrip', 2, 0, 2, 1),
  _item('directionPad', 0, 1, 2, 3),
  _item('keyboard', 2, 1, 1, 1),
  _item('mute', 3, 1, 1, 1),
  _item('volumeRocker', 2, 2, 2, 1),
  _item('channelRocker', 2, 3, 2, 1),
  _item('apps', 0, 4, 2, 1),
  _item('inputs', 2, 4, 2, 1),
  _item('volumeSlider', 0, 5, 4, 1),
], configuredRows: 6);

GridItem _item(String definitionId, int x, int y, int w, int h) => GridItem(
  id: 'default-${definitionId}',
  definitionId: definitionId,
  x: x,
  y: y,
  w: w,
  h: h,
);
