import 'package:remote_core/remote_core.dart';

import '../host/remote_panel.dart';

import '../configuration/remote_setting.dart';
import '../elements/remote_element.dart';
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
  int get minimumWidth => layout.size?.minimumWidth ?? _linearWidth;
  int get minimumHeight => layout.size?.minimumHeight ?? _linearHeight;

  bool get _vertical => axis == ItemAxis.vertical;
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

  /// Eligibility: can this item be offered for a device with [capabilities]?
  bool isCompatibleWith(Set<RemoteCapability> capabilities) =>
      id != 'unknown' && requires.every(capabilities.contains);

  /// Whether the connected session reports every required capability.
  bool isSupportedBy(RemotePanel remote) => requires.every(remote.supports);

  /// Runtime availability: connected, idle and supported.
  bool isAvailableOn(RemotePanel remote) =>
      remote.ready && isSupportedBy(remote);
  final List<RemoteElement<TDevice>> elements;
}
