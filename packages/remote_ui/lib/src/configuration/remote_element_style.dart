/// Overrides for one stable element ID within an item.
final class RemoteElementStyle {
  const RemoteElementStyle({this.iconSize, this.foreground});

  final double? iconSize;
  final int? foreground;

  factory RemoteElementStyle.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const RemoteElementStyle();
    }
    final size = value['iconSize'];
    final color = value['foreground'];
    return RemoteElementStyle(
      iconSize: size is num && size.isFinite
          ? size.toDouble().clamp(12, 36)
          : null,
      foreground: color is int && color >= 0 && color <= 0xffffffff
          ? color
          : null,
    );
  }

  Map<String, Object?> toJson() => {
    if (iconSize != null) 'iconSize': iconSize,
    if (foreground != null) 'foreground': foreground,
  };
}
