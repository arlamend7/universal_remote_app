import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/src/engines/ssap/pointer/ssap_pointer_connection.dart';
import 'package:test/test.dart';

import '../../support/fake_transport.dart';

void main() {
  test('pointer movement, scroll, click and keypad frames are delimited and validated', () async {
    final transport = FakeTransport();
    final pointer = SsapPointerConnection(
      connector: (_) async => transport,
      onUnavailable: () {},
    );
    await pointer.open(
      'ws://127.0.0.1:3000/pointer',
      Uri.parse('ws://127.0.0.1:3000'),
      allowInsecure: true,
    );
    await pointer.motion('move', 12, -5);
    await pointer.motion('scroll', 0, 2);
    await pointer.click();
    await pointer.button(RemoteKey.digit7.wireName);
    expect(transport.frames[0], contains('type:move\ndx:12\ndy:-5'));
    expect(transport.frames[1], contains('type:scroll'));
    expect(transport.frames[2], 'type:click\n\n');
    expect(transport.frames[3], 'type:button\nname:7\n\n');
    expect(transport.frames.every((frame) => frame.endsWith('\n\n')), true);
    expect(() => pointer.motion('move', double.nan, 0), throwsArgumentError);
    await pointer.close();
  });
}
