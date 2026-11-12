/// A session that accepts a short code shown by its device.
abstract interface class PairingCodeReceiver {
  /// True while the device displays a code and waits for it; devices that
  /// pair by on-screen approval never wait for a code.
  bool get awaitingPairingCode;

  Future<bool> submitPairingCode(String code);
}
