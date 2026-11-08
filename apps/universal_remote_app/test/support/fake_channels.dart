final class FakeChannels {
  int adjustments = 0;
  Future<void> channelUp() async {
    adjustments++;
  }

  Future<void> channelDown() async {
    adjustments--;
  }
}
