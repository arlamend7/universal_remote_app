import 'package:remote_core/remote_core.dart';

final class RecordingPairingReceiver implements PairingCodeReceiver {
  final submitted = <String>[];

  @override
  bool get awaitingPairingCode => true;

  @override
  Future<bool> submitPairingCode(String code) async {
    submitted.add(code);
    return code == 'A1B2C3';
  }
}
