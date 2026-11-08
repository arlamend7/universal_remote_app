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
  });

  static const defaultCornerRadius = 12.0;

  final int? background, foreground, borderColor;
  final double padding, opacity, borderWidth, cornerRadius;
  final bool showBorder;

  bool get isRounded => cornerRadius > 0;

  bool get isDefault =>
      background == null &&
      foreground == null &&
      padding == 0 &&
      opacity == 1 &&
      !showBorder &&
      cornerRadius == defaultCornerRadius;

  RemoteItemStyle copyWith({
    Object? background = _keep,
    Object? foreground = _keep,
    Object? borderColor = _keep,
    double? padding,
    double? opacity,
    bool? showBorder,
    double? borderWidth,
    double? cornerRadius,
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
  );

  static const _keep = Object();

  factory RemoteItemStyle.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const RemoteItemStyle();
    }
    return RemoteItemStyle(
      background: _color(value['background']),
      foreground: _color(value['foreground']),
      padding: _number(value['padding'], 0, 8, 0),
      opacity: _number(value['opacity'], .3, 1, 1),
      showBorder: value['border'] == true,
      borderColor: _color(value['borderColor']),
      borderWidth: _number(value['borderWidth'], 1, 4, 1),
      cornerRadius: _number(value['radius'], 0, 28, defaultCornerRadius),
    );
  }

  static int? _color(Object? value) =>
      value is int && value >= 0 && value <= 0xffffffff ? value : null;

  static double _number(
    Object? value,
    double min,
    double max,
    double fallback,
  ) => value is num && value.isFinite
      ? value.toDouble().clamp(min, max)
      : fallback;

  Map<String, Object?> toJson() => {
    if (background != null) 'background': background,
    if (foreground != null) 'foreground': foreground,
    if (padding != 0) 'padding': padding,
    if (opacity != 1) 'opacity': opacity,
    if (showBorder) 'border': true,
    if (showBorder && borderColor != null) 'borderColor': borderColor,
    if (showBorder && borderWidth != 1) 'borderWidth': borderWidth,
    if (cornerRadius != defaultCornerRadius) 'radius': cornerRadius,
  };
}
