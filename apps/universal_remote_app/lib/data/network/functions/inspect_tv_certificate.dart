import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

Future<PeerCertificate> inspectTvCertificate(Uri endpoint) async {
  try {
    return await inspectPeerCertificate(endpoint);
  } catch (_) {
    throw const RemoteException(
      'certificateInspection',
      'Could not read the TV certificate. Keep the TV on, confirm its IP address, '
          'and check local-network access, then retry.',
    );
  }
}
