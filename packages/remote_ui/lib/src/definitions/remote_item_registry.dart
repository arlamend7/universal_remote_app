import 'package:remote_core/remote_core.dart';

import '../layout/models/grid_item.dart';
import '../items/ac_items.dart';
import '../items/standard_items.dart';
import '../items/tv_item_registration.dart';
import 'enums/item_axis.dart';
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

  static bool isRegistered(String id) => _entries.containsKey(id);

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
      _entries[id] ?? _entries['unknown']!;
}

extension RegisteredGridItem on GridItem {
  RemoteItemDefinition<Object> get definition =>
      RemoteItemRegistry.resolve(definitionId);

  bool get isGroup => definition.layout is GroupLayout;

  /// How the item's elements are arranged. Only the user's Position (or the
  /// definition's default) decides it, never the item's current size.
  ItemAxis get arrangement {
    final definition = this.definition;
    if (!definition.supportsPosition) {
      return definition.axis;
    }
    return position ?? definition.defaultPosition!;
  }

  /// The smallest size in the item's current arrangement.
  ({int width, int height}) get minimumSize =>
      definition.minimumFor(arrangement);

  /// The item arranged along [next]. Changing Position swaps the whole
  /// footprint (width and height, and so the effective minimum); it is the
  /// only operation that does. Items without a Position stay as they are.
  GridItem withPosition(ItemAxis next) {
    if (!definition.supportsPosition || next == arrangement) {
      return this;
    }
    return copy(position: next, w: h, h: w);
  }

  /// The item arranged for a resize to [width] by [height]. Keeps its
  /// Position unless that shape is below the current Position's minimum but
  /// valid for the other one (a 2 × 1 horizontal pair dragged to 1 × 2 turns
  /// vertical). Only the Position changes; the size is the caller's.
  GridItem arrangedFor(int width, int height) {
    final current = minimumSize;
    final fitsCurrent = width >= current.width && height >= current.height;
    if (fitsCurrent || !definition.supportsPosition) {
      return this;
    }
    final other = arrangement == ItemAxis.horizontal
        ? ItemAxis.vertical
        : ItemAxis.horizontal;
    final swapped = definition.minimumFor(other);
    final fitsOther = width >= swapped.width && height >= swapped.height;
    if (!fitsOther) {
      return this;
    }
    return copy(position: other);
  }

  /// A saved item whose definition this version cannot draw.
  bool get isUnavailable => definition.layout is UnavailableLayout;
}
