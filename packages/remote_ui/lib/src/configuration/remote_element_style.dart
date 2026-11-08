import 'style_json.dart';

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
    return RemoteElementStyle(
      iconSize: size is num && size.isFinite
          ? parseStyleNumber(size, 12, 36, 24)
          : null,
      foreground: parseStyleColor(value['foreground']),
    );
  }

  Map<String, Object?> toJson() => {
    if (iconSize != null) 'iconSize': iconSize,
    if (foreground != null) 'foreground': foreground,
  };
}
