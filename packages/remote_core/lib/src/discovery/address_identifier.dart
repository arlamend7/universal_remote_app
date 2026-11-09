import '../discovery.dart';

/// Checks one user-supplied address without pairing or sending commands.
abstract interface class AddressIdentifier {
  Future<bool> recognizesAddress(
    String address,
    DiscoveryCancellation cancellation,
  );
}
