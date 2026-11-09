import 'package:remote_core/remote_core.dart';

final class RecordingPairingReceiver implements PairingCodeReceiver {
  final submitted = <String>[];

  @override
  Future<bool> submitPairingCode(String code) async {
    submitted.add(code);
    return code == 'A1B2C3';
  }
}
