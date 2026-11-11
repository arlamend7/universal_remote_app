import 'package:remote_core/remote_core.dart';

RemoteException ssapCommandError(Object? raw, {required bool registration}) {
  if (registration) {
    return const RemoteException(
      'pairingRejected',
      'The TV rejected registration. Approve pairing on the TV or re-pair this device.',
    );
  }
  final text = '$raw'.toLowerCase();
  if (text.contains('401') ||
      text.contains('403') ||
      text.contains('permission')) {
    return const RemoteException(
      'permission',
      'The TV denied permission for this control. Re-pairing may be required.',
    );
  }
  if (text.contains('404') ||
      text.contains('not found') ||
      text.contains('not supported')) {
    return const RemoteException(
      'unsupported',
      'This TV does not support this control.',
    );
  }
  return const RemoteException(
    'command',
    'The TV could not complete this control.',
  );
}
