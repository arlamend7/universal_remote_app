/// A session that accepts a short code shown by its device.
abstract interface class PairingCodeReceiver {
  /// True while the device displays a code and waits for it; devices that
  /// pair by on-screen approval never wait for a code.
  bool get awaitingPairingCode;

  /// The character set and length requested by the active pairing protocol.
  ({int length, String characters, bool numeric}) get pairingCodeFormat;

  Future<bool> submitPairingCode(String code);
}
