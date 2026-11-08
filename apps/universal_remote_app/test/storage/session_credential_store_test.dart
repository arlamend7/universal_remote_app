import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/data/pairing/repositories/session_credential_store.dart';

import '../support/counting_credential_store.dart';

void main() {
  test('concurrent reconnects read once, unchanged keys do not write, and deletion invalidates reuse', () async {
    final backing = CountingCredentialStore()..keys['tv'] = 'test-key';
    final cache = SessionCredentialStore(backing);
    expect(await Future.wait([cache.read('tv'), cache.read('tv')]), [
      'test-key',
      'test-key',
    ]);
    expect(backing.reads, 1);
    await cache.write('tv', 'test-key');
    expect(backing.writes, 0);
    await cache.write('tv', 'rotated-test-key');
    expect(backing.writes, 1);
    expect(await cache.read('tv'), 'rotated-test-key');
    expect(backing.reads, 1);
    final deletion = cache.delete('tv');
    final readAfterDelete = cache.read('tv');
    await deletion;
    expect(await readAfterDelete, isNull);
    expect(backing.deletes, 1);
    expect(backing.reads, 2);
    cache.dispose();
    await expectLater(cache.read('tv'), throwsA(isA<RemoteException>()));
  });
  test('denied access is not cached and a new session reads protected storage again', () async {
    final backing = CountingCredentialStore()..keys['tv'] = 'test-key';
    final cache = SessionCredentialStore(backing);
    backing.failRead = true;
    await expectLater(cache.read('tv'), throwsA(isA<RemoteException>()));
    backing.failRead = false;
    expect(await cache.read('tv'), 'test-key');
    expect(backing.reads, 2);
    cache.dispose();
    final restarted = SessionCredentialStore(backing);
    expect(await restarted.read('tv'), 'test-key');
    expect(backing.reads, 3);
    restarted.dispose();
  });
}
