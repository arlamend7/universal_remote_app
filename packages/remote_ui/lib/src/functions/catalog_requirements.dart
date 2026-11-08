import 'package:remote_core/remote_core.dart';

import '../layout/models/enums/grid_widget_kind.dart';
import '../definitions/remote_item_definition.dart';

bool isCatalogCompatible(
  RemoteItemDefinition<Object> definition,
  Set<RemoteCapability> capabilities,
) =>
    definition.kind != GridWidgetKind.unknown &&
    definition.requires.every(capabilities.contains);
