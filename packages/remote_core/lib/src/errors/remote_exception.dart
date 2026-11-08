/// Safe presentation error; never put raw authentication payloads in messages.
class RemoteException implements Exception {
  const RemoteException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}
