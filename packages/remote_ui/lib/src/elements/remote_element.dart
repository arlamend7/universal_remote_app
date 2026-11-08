import 'package:flutter/widgets.dart' show IconData;

import 'remote_element_context.dart';

abstract class RemoteElement<TDevice> {
  const RemoteElement(this.id, {this.slots = 1, this.icon}) : assert(slots > 0);

  final String id;

  /// Relative space this element takes in a row or column.
  final int slots;

  final IconData Function(RemoteElementContext context)? icon;
}
