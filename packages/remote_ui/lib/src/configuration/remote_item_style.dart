import 'style_json.dart';
import 'enums/remote_border_shape.dart';

/// A dashboard item's visual overrides, stored independently of its elements.
final class RemoteItemStyle {
  const RemoteItemStyle({
    this.background,
    this.foreground,
    this.padding = 0,
    this.opacity = 1,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1,
    this.cornerRadius = defaultCornerRadius,
    this.showBackground = false,
  });

  static const defaultCornerRadius = 12.0;

  final int? background, foreground, borderColor;
  final double padding, opacity, borderWidth, cornerRadius;
  final bool showBorder;

  /// Whether the item's outer container paints a background: [background]
  /// when set, otherwise the theme's card colour. Off (the default) leaves the
  /// container transparent; borders and the controls inside keep their own
  /// colours.
  final bool showBackground;

  bool get isRounded => cornerRadius > 0;

  bool get isDefault =>
      background == null &&
      foreground == null &&
      padding == 0 &&
      opacity == 1 &&
      !showBorder &&
      borderColor == null &&
      borderWidth == 1 &&
      cornerRadius == defaultCornerRadius &&
      !showBackground;

  RemoteItemStyle copyWith({
    Object? background = _keep,
    Object? foreground = _keep,
    Object? borderColor = _keep,
    double? padding,
    double? opacity,
    bool? showBorder,
    double? borderWidth,
    double? cornerRadius,
    bool? showBackground,
  }) => RemoteItemStyle(
    background: identical(background, _keep)
        ? this.background
        : background as int?,
    foreground: identical(foreground, _keep)
        ? this.foreground
        : foreground as int?,
    borderColor: identical(borderColor, _keep)
        ? this.borderColor
        : borderColor as int?,
    padding: padding ?? this.padding,
    opacity: opacity ?? this.opacity,
    showBorder: showBorder ?? this.showBorder,
    borderWidth: borderWidth ?? this.borderWidth,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    showBackground: showBackground ?? this.showBackground,
  );

  static const _keep = Object();

  factory RemoteItemStyle.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const RemoteItemStyle();
    }
    return RemoteItemStyle(
      background: parseStyleColor(value['background']),
      foreground: parseStyleColor(value['foreground']),
      padding: parseStyleNumber(value['padding'], 0, 8, 0),
      opacity: parseStyleNumber(value['opacity'], .3, 1, 1),
      showBorder: value['border'] == true,
      borderColor: parseStyleColor(value['borderColor']),
      borderWidth: parseStyleNumber(value['borderWidth'], 1, 4, 1),
      cornerRadius: parseStyleNumber(
        value['radius'],
        0,
        RemoteBorderShape.circle.radius,
        defaultCornerRadius,
      ),
      showBackground: value['showBackground'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    if (background != null) 'background': background,
    if (foreground != null) 'foreground': foreground,
    if (padding != 0) 'padding': padding,
    if (opacity != 1) 'opacity': opacity,
    if (showBorder) 'border': true,
    if (borderColor != null) 'borderColor': borderColor,
    if (borderWidth != 1) 'borderWidth': borderWidth,
    if (cornerRadius != defaultCornerRadius) 'radius': cornerRadius,
    if (showBackground) 'showBackground': true,
  };
}
