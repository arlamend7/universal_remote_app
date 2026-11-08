import '../layout/models/enums/grid_widget_kind.dart';

/// Grid footprint of controls whose elements are not laid out in a single line.
(int width, int height, int minWidth, int minHeight)? compositeFootprint(
  GridWidgetKind kind,
) => switch (kind) {
  GridWidgetKind.directionPad => (2, 3, 2, 3),
  GridWidgetKind.crossPad => (3, 3, 3, 3),
  GridWidgetKind.navigationStrip ||
  GridWidgetKind.channelDisplay ||
  GridWidgetKind.currentApp ||
  GridWidgetKind.watch ||
  GridWidgetKind.deviceName => (2, 1, 2, 1),
  GridWidgetKind.touchpad || GridWidgetKind.artwork => (4, 3, 4, 3),
  GridWidgetKind.keypad => (3, 4, 3, 4),
  GridWidgetKind.volumeDial || GridWidgetKind.inputGrid => (2, 2, 2, 2),
  GridWidgetKind.volumeExpanded || GridWidgetKind.seek => (4, 2, 4, 2),
  GridWidgetKind.appStrip ||
  GridWidgetKind.appCarousel ||
  GridWidgetKind.targetTemperature => (4, 1, 2, 1),
  GridWidgetKind.appGrid || GridWidgetKind.channelGroup => (4, 2, 2, 2),
  GridWidgetKind.recentApps ||
  GridWidgetKind.inputStrip ||
  GridWidgetKind.currentActivity => (4, 1, 4, 1),
  GridWidgetKind.transport => (3, 1, 3, 1),
  GridWidgetKind.group => (4, 3, 1, 1),
  GridWidgetKind.volumePreset => (1, 1, 1, 1),
  _ => null,
};
