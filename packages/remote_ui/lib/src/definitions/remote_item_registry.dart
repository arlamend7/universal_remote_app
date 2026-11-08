import '../elements/remote_element.dart';
import '../layout/models/grid_item.dart';
import '../layout/models/enums/grid_widget_kind.dart';
import '../items/ac_items.dart';
import '../items/standard_items.dart';
import '../items/tv_item_registration.dart';
import 'remote_item_definition.dart';

/// A single registry for persisted references, catalog eligibility and rendering.
abstract final class RemoteItemRegistry {
  static final _entries = {
    for (final item in <RemoteItemDefinition<Object>>[
      ...standardItemDefinitions,
      ...tvItemDefinitions,
      ...AcItems.definitions,
    ])
      item.kind: item,
  };

  static RemoteItemDefinition<Object> resolve(GridWidgetKind kind) =>
      _entries[kind] ??
      (throw StateError('No remote item registered for ${kind.name}.'));
}

extension RegisteredGridElements on GridItem {
  E element<E extends RemoteElement<Object>>(E reference) =>
      RemoteItemRegistry.resolve(kind).element(reference);
}
