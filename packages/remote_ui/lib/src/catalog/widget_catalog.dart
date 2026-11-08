import '../definitions/remote_item_registry.dart';
import '../layout/models/enums/grid_widget_kind.dart';
import '../definitions/remote_item_definition.dart';

abstract final class WidgetCatalog {
  static final definitions = List<RemoteItemDefinition<Object>>.unmodifiable(
    GridWidgetKind.values.map(definition),
  );

  static RemoteItemDefinition<Object> definition(GridWidgetKind kind) =>
      RemoteItemRegistry.resolve(kind);

  static List<RemoteItemDefinition<Object>> variations(GridWidgetKind kind) =>
      definitions
          .where((item) => item.category == definition(kind).category)
          .toList();
}
