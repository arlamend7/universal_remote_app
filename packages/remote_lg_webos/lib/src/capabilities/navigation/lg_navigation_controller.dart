import 'package:remote_core/remote_core.dart';

import '../../pointer/services/lg_pointer_connection.dart';

final class LgNavigationController {
  LgNavigationController(this.pointer);
  final LgPointerConnection pointer;
  Future<void> press(NavigationKey key) async {
    pointer.press(key);
  }
}
