import 'package:remote_network/remote_network.dart';
import 'package:test/test.dart';

void main() {
  test(
    'directed broadcast uses the actual subnet rather than guessing /24',
    () {
      expect(
        ipv4BroadcastAddress('172.16.1.13', '255.255.255.0'),
        '172.16.1.255',
      );
      expect(
        ipv4BroadcastAddress('172.16.1.130', '255.255.255.192'),
        '172.16.1.191',
      );
      expect(
        ipv4BroadcastAddress('172.16.1.13', '255.255.254.0'),
        '172.16.1.255',
      );
      expect(ipv4BroadcastAddress('172.16.1.13', '255.0.255.0'), isNull);
      expect(ipv4BroadcastAddress('172.16.1.13', '255.255.255.254'), isNull);
      expect(ipv4BroadcastAddress('172.16.1.255', '255.255.255.0'), isNull);
    },
  );
}
