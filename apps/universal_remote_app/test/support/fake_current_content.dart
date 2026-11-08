import 'dart:async';

import 'package:remote_core/remote_core.dart';

final class FakeCurrentContent {
  CurrentContent value = const CurrentContent(
    appId: 'test.youtube',
    appName: 'YouTube',
  );
  bool unavailable = false;
  Completer<CurrentContent>? pending;
  final events = StreamController<CurrentContent>.broadcast();
  Future<CurrentContent> currentContent() async {
    if (unavailable) {
      throw const RemoteException('permission', 'Current content unavailable.');
    }
    return pending?.future ?? value;
  }

  Stream<CurrentContent> watchCurrentContent() => events.stream;
  void update(CurrentContent content) {
    value = content;
    events.add(content);
  }

  Future<void> dispose() => events.close();
}
