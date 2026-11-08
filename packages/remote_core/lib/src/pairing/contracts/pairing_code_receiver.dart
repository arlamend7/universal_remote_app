/// A session that accepts a short code shown by its device.
abstract interface class PairingCodeReceiver {
  Future<bool> submitPairingCode(String code);
}
