import 'package:flutter_test/flutter_test.dart';
import 'package:remote_core/remote_core.dart';
import 'package:universal_remote_app/data/pairing/repositories/secure_credential_store.dart';

import '../support/unavailable_secure_storage.dart';

void main() {
  test('native credential failures are typed without exposing keys or native details', () async {
    final store = SecureCredentialStore(UnavailableSecureStorage());
    final matcher = throwsA(
      isA<RemoteException>()
          .having((error) => error.code, 'code', 'credentialStorage')
          .having(
            (error) => error.message,
            'safe message',
            isNot(contains('sensitive')),
          ),
    );
    await expectLater(store.read('device'), matcher);
    await expectLater(store.write('device', 'sensitive-client-key'), matcher);
    await expectLater(store.delete('device'), matcher);
  });
}
