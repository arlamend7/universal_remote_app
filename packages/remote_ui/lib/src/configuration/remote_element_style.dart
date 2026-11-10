import 'style_json.dart';
import 'enums/remote_border_shape.dart';

/// Overrides for one stable element ID within an item.
final class RemoteElementStyle {
  const RemoteElementStyle({
    this.iconSize,
    this.foreground,
    this.borderWidth = 0,
    this.cornerRadius = 0,
    this.visible = true,
    this.label,
    this.showLabel,
    this.showIcon,
    this.repeat,
    this.showOfflineIndicator = false,
  });

  final double? iconSize;
  final int? foreground;
  final double borderWidth, cornerRadius;
  final bool visible, showOfflineIndicator;
  final bool? showLabel, showIcon;
  final String? label;
  final bool? repeat;

  RemoteElementStyle copyWith({
    double? borderWidth,
    double? cornerRadius,
    bool? visible,
    String? label,
    bool? showLabel,
    bool? showIcon,
    bool? repeat,
    bool? showOfflineIndicator,
  }) => RemoteElementStyle(
    iconSize: iconSize,
    foreground: foreground,
    borderWidth: borderWidth ?? this.borderWidth,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    visible: visible ?? this.visible,
    label: label == '' ? null : label ?? this.label,
    showLabel: showLabel ?? this.showLabel,
    showIcon: showIcon ?? this.showIcon,
    repeat: repeat ?? this.repeat,
    showOfflineIndicator: showOfflineIndicator ?? this.showOfflineIndicator,
  );

  factory RemoteElementStyle.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const RemoteElementStyle();
    }
    final size = value['iconSize'];
    final label = value['label'];
    return RemoteElementStyle(
      iconSize: size is num && size.isFinite
          ? parseStyleNumber(size, 12, 36, 24)
          : null,
      foreground: parseStyleColor(value['foreground']),
      borderWidth: parseStyleNumber(value['borderWidth'], 0, 4, 0),
      cornerRadius: parseStyleNumber(
        value['radius'],
        0,
        RemoteBorderShape.circle.radius,
        0,
      ),
      visible: value['visible'] != false,
      label: label is String && label.trim().isNotEmpty ? label : null,
      showLabel: value['showLabel'] is bool ? value['showLabel'] as bool : null,
      showIcon: value['showIcon'] is bool ? value['showIcon'] as bool : null,
      showOfflineIndicator: value['showOfflineIndicator'] == true,
      repeat: value['repeat'] is bool ? value['repeat'] as bool : null,
    );
  }

  Map<String, Object?> toJson() => {
    if (iconSize != null) 'iconSize': iconSize,
    if (foreground != null) 'foreground': foreground,
    if (borderWidth != 0) 'borderWidth': borderWidth,
    if (cornerRadius != 0) 'radius': cornerRadius,
    if (!visible) 'visible': false,
    if (label != null) 'label': label,
    if (showLabel != null) 'showLabel': showLabel,
    if (showIcon != null) 'showIcon': showIcon,
    if (showOfflineIndicator) 'showOfflineIndicator': true,
    if (repeat != null) 'repeat': repeat,
  };
}
