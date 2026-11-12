abstract interface class InterstitialAdvertising {
  Future<void> prepare();

  /// Shows a preloaded ad at the current break, if one is ready.
  Future<void> show({
    required bool Function() canPresent,
    required void Function(bool) onVisible,
    required void Function() onShown,
  });

  void dispose();
}
