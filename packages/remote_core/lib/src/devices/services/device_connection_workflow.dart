/// Coordinates wake and bounded connection retries without UI or protocol state.
final class DeviceConnectionWorkflow {
  const DeviceConnectionWorkflow({
    this.retryDelay = const Duration(seconds: 2),
    this.wakeAttempts = 8,
  }) : assert(wakeAttempts > 0);

  final Duration retryDelay;
  final int wakeAttempts;

  Future<void> run({
    required Future<void> Function() connect,
    required bool Function() isCurrent,
    Future<void> Function()? wake,
    required bool Function(Object) canRetry,
    required Future<void> Function() reset,
  }) async {
    if (!isCurrent()) {
      return;
    }
    await wake?.call();
    final limit = wake == null ? 1 : wakeAttempts;
    for (var attempt = 1; attempt <= limit && isCurrent(); attempt++) {
      final failure = await _attempt(connect);
      if (failure == null || !isCurrent()) {
        return;
      }
      if (attempt == limit || !canRetry(failure.$1)) {
        Error.throwWithStackTrace(failure.$1, failure.$2);
      }
      await reset();
      await Future<void>.delayed(retryDelay);
    }
  }

  Future<(Object, StackTrace)?> _attempt(
    Future<void> Function() connect,
  ) async {
    try {
      await connect();
      return null;
    } catch (error, stack) {
      return (error, stack);
    }
  }
}
