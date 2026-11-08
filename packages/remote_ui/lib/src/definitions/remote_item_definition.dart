import 'package:remote_core/remote_core.dart';

import '../layout/models/enums/grid_widget_kind.dart';
import '../layout/models/enums/item_orientation.dart';
import 'composite_footprint.dart';
import '../elements/remote_element.dart';
import 'enums/remote_item_category.dart';

final class RemoteItemDefinition<TDevice> {
  const RemoteItemDefinition(
    this.kind,
    this.name,
    this.category, {
    this.defaultPosition = ItemOrientation.horizontal,
    this.description,
    this.requires = const {},
    this.elements = const [],
  }) : assert(defaultPosition != ItemOrientation.automatic);

  final GridWidgetKind kind;
  final String name;
  final RemoteItemCategory category;
  final ItemOrientation defaultPosition;

  int get width => compositeFootprint(kind)?.$1 ?? _linearWidth;
  int get height => compositeFootprint(kind)?.$2 ?? _linearHeight;
  int get minimumWidth => compositeFootprint(kind)?.$3 ?? _linearWidth;
  int get minimumHeight => compositeFootprint(kind)?.$4 ?? _linearHeight;

  bool get _vertical => defaultPosition == ItemOrientation.vertical;
  int get _slots => elements.isEmpty
      ? 1
      : elements.fold(0, (total, element) => total + element.slots);
  int get _linearWidth => _vertical ? 1 : _slots;
  int get _linearHeight => _vertical ? _slots : 1;

  final String? description;
  String get searchText => '$name ${category.name} ${description ?? ''}';
  bool accepts(int w, int h) =>
      w >= minimumWidth && w <= 4 && h >= minimumHeight && h <= 16;

  final Set<RemoteCapability> requires;
  final List<RemoteElement<TDevice>> elements;

  E? findElement<E extends RemoteElement<Object>>(E reference) => elements
      .whereType<E>()
      .where((element) => element.id == reference.id)
      .firstOrNull;

  E element<E extends RemoteElement<Object>>(E reference) {
    final registered = findElement(reference);
    if (registered == null) {
      throw StateError('Item ${kind.name} has no element ${reference.id}.');
    }
    return registered;
  }
}
