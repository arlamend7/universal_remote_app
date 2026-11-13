import '../../configuration/remote_item_style.dart';
import '../../configuration/remote_element_style.dart';
import '../../definitions/enums/item_axis.dart';

/// An instance, not a singleton widget type. Groups use relative child coordinates.
final class GridItem {
  GridItem({
    required this.id,
    required this.definitionId,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.position,
    this.style = const RemoteItemStyle(),
    Map<String, String> config = const {},
    Map<String, RemoteElementStyle> elementStyles = const {},
    List<GridItem> children = const [],
  }) : config = Map.unmodifiable(config),
       elementStyles = Map.unmodifiable(elementStyles),
       children = List.unmodifiable(children);
  final String id;
  final String definitionId;
  final RemoteItemStyle style;
  final Map<String, RemoteElementStyle> elementStyles;
  final int x, y, w, h;

  /// How the user arranged the elements, independent of [w] and [h]. Null for
  /// items whose minimum size is square, which have no Position to choose.
  final ItemAxis? position;
  final Map<String, String> config;
  final List<GridItem> children;

  /// The same item with no chosen Position, for definitions without one.
  GridItem withoutPosition() => GridItem(
    id: id,
    definitionId: definitionId,
    x: x,
    y: y,
    w: w,
    h: h,
    style: style,
    elementStyles: elementStyles,
    config: config,
    children: children,
  );

  GridItem copy({
    String? id,
    String? definitionId,
    int? x,
    int? y,
    int? w,
    int? h,
    ItemAxis? position,
    RemoteItemStyle? style,
    Map<String, RemoteElementStyle>? elementStyles,
    Map<String, String>? config,
    List<GridItem>? children,
  }) => GridItem(
    id: id ?? this.id,
    definitionId: definitionId ?? this.definitionId,
    x: x ?? this.x,
    y: y ?? this.y,
    w: w ?? this.w,
    h: h ?? this.h,
    position: position ?? this.position,
    style: style ?? this.style,
    elementStyles: elementStyles ?? this.elementStyles,
    config: config ?? this.config,
    children: children ?? this.children,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'definitionId': definitionId,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    if (position case final chosen?) 'position': chosen.name,
    if (!style.isDefault) 'style': style.toJson(),
    if (elementStyles.isNotEmpty)
      'elements': elementStyles.map(
        (id, style) => MapEntry(id, style.toJson()),
      ),
    'config': config,
    'children': children.map((item) => item.toJson()).toList(),
  };
  factory GridItem.fromJson(Map<String, dynamic> value) => _parse(value, 0);
  static GridItem _parse(Map<String, dynamic> value, int depth) {
    if (depth > 1) {
      throw const FormatException('Nested groups are not supported.');
    }
    final children = value['children'] as List<dynamic>? ?? [];
    return GridItem(
      id: value['id'] as String,
      definitionId: value['definitionId'] as String,
      style: RemoteItemStyle.fromJson(value['style']),
      elementStyles: _elementStyles(value['elements']),
      x: value['x'] as int,
      y: value['y'] as int,
      w: value['w'] as int,
      h: value['h'] as int,
      position: ItemAxis.values.asNameMap()[value['position']],
      config: (value['config'] as Map<String, dynamic>? ?? {})
          .cast<String, String>(),
      children: children
          .map((item) => _parse(item as Map<String, dynamic>, depth + 1))
          .toList(),
    );
  }

  static Map<String, RemoteElementStyle> _elementStyles(Object? value) {
    if (value is! Map<String, dynamic>) {
      return {};
    }
    return value.map(
      (id, style) => MapEntry(id, RemoteElementStyle.fromJson(style)),
    );
  }
}
