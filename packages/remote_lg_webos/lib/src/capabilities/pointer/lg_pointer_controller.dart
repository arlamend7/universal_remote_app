import 'package:remote_core/remote_core.dart';

import '../../pointer/services/lg_pointer_connection.dart';

final class LgPointerController {
  LgPointerController(this.pointer);
  final LgPointerConnection pointer;
  Future<void> move(double dx, double dy) async =>
      pointer.motion('move', dx, dy);
  Future<void> scroll(double dx, double dy) async =>
      pointer.motion('scroll', dx, dy);
  Future<void> click() async => pointer.click();
  Future<void> key(RemoteKey key) async => pointer.specialKey(key);
}
