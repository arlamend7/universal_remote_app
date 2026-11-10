import 'package:remote_core/remote_core.dart';

import '../layout/models/grid_item.dart';
import '../items/ac_items.dart';
import '../items/standard_items.dart';
import '../items/tv_item_registration.dart';
import 'layouts/layouts.dart';
import 'remote_item_definition.dart';

/// A single registry for persisted references, catalog eligibility and rendering.
abstract final class RemoteItemRegistry {
  /// Every registered definition, in catalog order.
  static final definitions = List<RemoteItemDefinition<Object>>.unmodifiable([
    ...tvItemDefinitions,
    ...standardItemDefinitions,
    ...AcItems.definitions,
  ]);

  static final _entries = {for (final item in definitions) item.id: item};

  static const _aliases = {'inputPicker': 'inputs', 'appLinks': 'appShortcut'};

  static bool isRegistered(String id) =>
      _entries.containsKey(_aliases[id] ?? id);

  /// The alternative looks of the control [id] belongs to, including itself.
  /// Only categories of alternatives offer any; other controls stand alone.
  static List<RemoteItemDefinition<Object>> variations(String id) {
    final definition = resolve(id);
    if (!definition.category.alternatives) {
      return [definition];
    }
    return definitions
        .where((item) => item.category == definition.category)
        .toList();
  }

  /// Definitions usable with [capabilities] whose text matches every word of
  /// [query].
  static List<RemoteItemDefinition<Object>> search({
    required Set<RemoteCapability> capabilities,
    String query = '',
    bool Function(RemoteItemDefinition<Object> definition)? where,
  }) {
    final words = _normalize(query).split(' ').where((word) => word.isNotEmpty);
    return [
      for (final definition in definitions)
        if (definition.isCompatibleWith(capabilities) &&
            (where?.call(definition) ?? true) &&
            words.every(_normalize(definition.searchText).contains))
          definition,
    ];
  }

  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  /// The definition for [id]. A saved id this version does not know (for
  /// example from a newer version) resolves to the unavailable placeholder
  /// and keeps its own id, so saving the dashboard does not lose it.
  static RemoteItemDefinition<Object> resolve(String id) =>
      _entries[_aliases[id] ?? id] ?? _entries['unknown']!;
}

extension RegisteredGridItem on GridItem {
  RemoteItemDefinition<Object> get definition =>
      RemoteItemRegistry.resolve(definitionId);

  bool get isGroup => definition.layout is GroupLayout;

  /// A saved item whose definition this version cannot draw.
  bool get isUnavailable => definition.layout is UnavailableLayout;
}
