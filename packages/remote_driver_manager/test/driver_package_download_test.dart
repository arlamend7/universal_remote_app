import 'dart:async';

import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_manager/src/distribution/driver_package_download.dart';
import 'package:test/test.dart';

void main() {
  test('one caller can cancel without aborting a shared transfer', () async {
    final first = StreamController<void>();
    final second = StreamController<void>();
    addTearDown(first.close);
    addTearDown(second.close);
    final observed = <double>[];
    final download = DriverPackageDownload((cancelled, report) async {
      await Future<void>.value();
      report(.5);
      await cancelled;
      throw const RemoteException('cancelled', 'Transfer cancelled.');
    });
    final firstResult = expectLater(
      download.join(cancellation: first.stream),
      throwsA(isA<RemoteException>()),
    );
    final secondResult = expectLater(
      download.join(cancellation: second.stream, progress: observed.add),
      throwsA(isA<RemoteException>()),
    );
    first.add(null);
    await firstResult;
    expect(download.cancelled, isFalse);
    expect(observed, [.5]);
    second.add(null);
    await secondResult;
    expect(download.cancelled, isTrue);
  });
}
