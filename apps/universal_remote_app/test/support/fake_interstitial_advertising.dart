import 'package:universal_remote_app/domains/session/contracts/interstitial_advertising.dart';

final class FakeInterstitialAdvertising implements InterstitialAdvertising {
  bool available = true;
  bool _ready = false;
  int presentations = 0;

  @override
  Future<void> prepare() async => _ready = available;

  @override
  Future<void> show({
    required bool Function() canPresent,
    required void Function(bool) onVisible,
    required void Function() onShown,
  }) async {
    if (!_ready || !canPresent()) {
      return;
    }
    _ready = false;
    onVisible(true);
    presentations++;
    onShown();
    onVisible(false);
  }

  @override
  void dispose() => _ready = false;
}
