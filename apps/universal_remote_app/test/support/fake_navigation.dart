import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';

class FakeNavigation {
  NavigationKey? last;
  Future<void> press(NavigationKey key) async {
    last = key;
  }
}
