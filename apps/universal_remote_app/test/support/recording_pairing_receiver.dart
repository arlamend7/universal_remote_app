import 'package:remote_core/remote_core.dart';

final class RecordingPairingReceiver implements PairingCodeReceiver {
  final submitted = <String>[];

  @override
  ({int length, String characters, bool numeric}) get pairingCodeFormat =>
      (length: 6, characters: '[0-9a-fA-F]', numeric: false);

  @override
  bool get awaitingPairingCode => true;

  @override
  Future<bool> submitPairingCode(String code) async {
    submitted.add(code);
    return code == 'A1B2C3';
  }
}
