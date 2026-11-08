import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_app/domains/discovery/functions/discovery_failure_message.dart';

void main() {
  test('permission and route failures have distinct actionable messages', () {
    final denied = discoveryFailureMessage(
      const SocketException('private details', osError: OSError('denied', 13)),
    );
    final route = discoveryFailureMessage(
      const SocketException(
        'private details',
        osError: OSError('unreachable', 65),
      ),
    );
    expect(denied, contains('blocked by the system'));
    expect(denied, contains('13'));
    expect(route, contains('route'));
    expect(route, contains('65'));
    expect(denied, isNot(contains('private details')));
  });
}
