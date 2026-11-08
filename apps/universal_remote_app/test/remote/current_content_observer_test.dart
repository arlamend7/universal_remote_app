import 'package:remote_ui/remote_ui.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';

import '../support/fake_controller.dart';
import '../support/test_device.dart';

void main() {
  test('content updates, failures and detached-session responses never become stale TV state', () async {
    final owner = FakeController(tv, enabledControls: true);
    final observer = CurrentContentObserver();
    await observer.observe(owner);
    expect(observer.value.value?.appName, 'YouTube');
    owner.contentControl.update(
      const CurrentContent(
        appId: 'com.webos.app.livetv',
        appName: 'Live TV',
        channelNumber: '7.1',
        channelName: 'CBC',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(observer.value.value?.channelNumber, '7.1');
    owner.contentControl.unavailable = true;
    await observer.refresh();
    expect(observer.value.value, isNull);
    owner.contentControl.unavailable = false;
    owner.contentControl.pending = Completer<CurrentContent>();
    final pending = observer.refresh();
    await observer.detach();
    owner.contentControl.pending!.complete(
      const CurrentContent(appId: 'stale', appName: 'Old TV'),
    );
    await pending;
    expect(observer.value.value, isNull);
    await observer.dispose();
    await owner.dispose();
  });
}
