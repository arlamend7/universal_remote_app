import '../layout/models/grid_item.dart';
import '../layout/models/grid_layout.dart';

/// Default remote layout inspired by the reference image.
/// 4 columns, with the directional pad centered.
GridLayout defaultRemoteGrid() => GridLayout([
  // Top-right control
  _item('currentActivity', 0, 0, 3, 1),
  
  _item('mute', 3, 0, 1, 1),

  // Main controls
  _item('volumeRocker', 0, 1, 1, 3),
  _item('directionPad', 1, 1, 2, 3),
  _item('channelRocker', 3, 1, 1, 3),

  // Bottom shortcuts
  _item('apps', 0, 4, 1, 1),
  _item('navigationStrip', 1, 4, 2, 1),
  _item('inputs', 3, 4, 1, 1),

  // Reserved area for optional shortcuts
], configuredRows: 6);

GridItem _item(
  String definitionId,
  int x,
  int y,
  int w,
  int h,
) => GridItem(
  id: 'default-$definitionId',
  definitionId: definitionId,
  x: x,
  y: y,
  w: w,
  h: h,
);