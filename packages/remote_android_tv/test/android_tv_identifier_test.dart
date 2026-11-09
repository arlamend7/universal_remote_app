import 'package:remote_android_tv/remote_android_tv.dart';
import 'package:remote_core/remote_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'only the declared Bonjour service on the Remote port is identified',
    () async {
      final probes = <String>[];
      final identifier = AndroidTvIdentifier(
        inspectIdentity: (host) async {
          probes.add(host);
          return 'fingerprint';
        },
      );
      final token = DiscoveryCancellation();
      DiscoveryObservation observation(String service, int port) =>
          DiscoveryObservation(
            protocolId: DiscoveryProtocol.bonjour,
            serviceType: service,
            endpoint: Uri.parse('tcp://192.168.1.42:$port'),
            metadata: {'name': 'TCL Google TV'},
          );
      expect(
        await identifier.identify(observation('_other._tcp', 6466), token),
        isNull,
      );
      expect(
        await identifier.identify(
          observation(AndroidTvIdentifier.service, 6467),
          token,
        ),
        isNull,
      );
      final match = await identifier.identify(
        observation(AndroidTvIdentifier.service, 6466),
        token,
      );
      expect(match?.profile.id, 'android-tv-fingerprint');
      expect(match?.profile.device.name, 'TCL Google TV');
      expect(match?.profile.device.metadata['verifiedPeerIdentity'], isNull);
      expect(
        match?.profile.device.metadata['advertisedPeerIdentity'],
        'fingerprint',
      );
      expect(probes, ['192.168.1.42']);
    },
  );
  test(
    'a recognized TCL service without a certificate is not stable identity',
    () async {
      final identifier = AndroidTvIdentifier(
        inspectIdentity: (_) async => null,
      );
      final match = await identifier.identify(
        DiscoveryObservation(
          protocolId: DiscoveryProtocol.bonjour,
          serviceType: AndroidTvIdentifier.service,
          endpoint: Uri.parse('tcp://192.168.1.43:6466'),
          metadata: {'name': 'TCL Google TV'},
        ),
        DiscoveryCancellation(),
      );
      expect(match?.profile.device.stableIdentity, isFalse);
      expect(match?.profile.device.metadata, isEmpty);
    },
  );
}
