import 'dart:convert';

import 'grid_item.dart';

final class GridLayout {
  GridLayout(Iterable<GridItem> items) : items = List.unmodifiable(items);
  final List<GridItem> items;
  int get occupiedRows => items.fold(
    1,
    (rows, item) => rows > item.y + item.h ? rows : item.y + item.h,
  );
  int get rows => items.fold(
    8,
    (rows, item) => rows > item.y + item.h ? rows : item.y + item.h,
  );
  String encode() => jsonEncode({
    'version': 2,
    'items': items.map((item) => item.toJson()).toList(),
  });
  factory GridLayout.decode(String raw) {
    final value = jsonDecode(raw) as Map<String, dynamic>;
    if (value['version'] != 2) {
      throw const FormatException('Unsupported remote grid version.');
    }
    return GridLayout(
      (value['items'] as List<dynamic>).map(
        (item) => GridItem.fromJson(item as Map<String, dynamic>),
      ),
    );
  }
}
