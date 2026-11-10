import 'package:remote_core/remote_core.dart';

import '../host/remote_panel.dart';

import '../configuration/remote_setting.dart';
import '../elements/remote_element.dart';
import '../elements/remote_action.dart';
import 'enums/item_axis.dart';
import 'enums/remote_item_category.dart';
import 'layouts/layouts.dart';

final class RemoteItemDefinition<TDevice> {
  const RemoteItemDefinition(
    this.id,
    this.name,
    this.category, {
    this.axis = ItemAxis.horizontal,
    this.description,
    this.requires = const {},
    this.requiresAny = const [],
    this.collectionAlternative,
    this.elements = const [],
    this.layout = const LinearLayout(),
    this.settings = const [],
  });

  final String id;

  /// Options the user can change for this item, beyond the common name and
  /// appearance ones.
  final List<RemoteSetting> settings;

  RemoteSetting setting(String key) =>
      settings.firstWhere((setting) => setting.key == key);

  /// How the elements are arranged and drawn.
  final RemoteItemLayout layout;

  final String name;
  final RemoteItemCategory category;

  /// The direction elements are laid out in, and the side an item grows along.
  final ItemAxis axis;

  int get width => layout.size?.width ?? _linearWidth;
  int get height => layout.size?.height ?? _linearHeight;
  int get minimumWidth =>
      layout.size?.minimumWidth ?? (_adaptive ? 1 : _linearWidth);
  int get minimumHeight =>
      layout.size?.minimumHeight ?? (_adaptive ? 1 : _linearHeight);

  bool get _adaptive => switch (layout) {
    LinearLayout(:final adaptive) => adaptive,
    _ => false,
  };

  /// The direction the elements run for an item of this shape.
  ItemAxis axisFor(int width, int height) {
    if (!_adaptive || width == height) {
      return axis;
    }
    return width > height ? ItemAxis.horizontal : ItemAxis.vertical;
  }

  bool get _vertical => axis == ItemAxis.vertical;
  int get _slots => elements.isEmpty
      ? 1
      : elements.fold(0, (total, element) => total + element.slots);
  int get _linearWidth => _vertical ? 1 : _slots;
  int get _linearHeight => _vertical ? _slots : 1;

  final String? description;
  String get searchText => '$name ${category.label} ${description ?? ''}';
  bool accepts(int w, int h) {
    final inRange =
        w >= minimumWidth && w <= 4 && h >= minimumHeight && h <= 16;
    if (!_adaptive) {
      return inRange;
    }
    // The side the elements run along must hold all of them.
    final run = axisFor(w, h) == ItemAxis.horizontal ? w : h;
    return inRange && run >= _slots;
  }

  final Set<RemoteCapability> requires;
  final List<Set<RemoteCapability>> requiresAny;

  /// A single action used when a collection is unavailable or a target is set manually.
  final ({
    RemoteCapability primary,
    RemoteCapability fallback,
    RemoteAction<TDevice> action,
    String? setting,
  })?
  collectionAlternative;

  bool _supports(bool Function(RemoteCapability) has) =>
      requires.every(has) &&
      (requiresAny.isEmpty || requiresAny.any((group) => group.every(has)));

  /// Eligibility: can this item be offered for a device with [capabilities]?
  bool isCompatibleWith(Set<RemoteCapability> capabilities) =>
      id != 'unknown' && _supports(capabilities.contains);

  /// Whether the connected session reports every required capability.
  bool isSupportedBy(RemotePanel remote) => _supports(remote.supports);

  /// Runtime availability: connected, idle and supported.
  bool isAvailableOn(RemotePanel remote) =>
      remote.ready && isSupportedBy(remote);
  final List<RemoteElement<TDevice>> elements;
}
