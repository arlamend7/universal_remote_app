/// How finely a session countdown reads and refreshes.
enum CountdownPrecision {
  /// Hours and minutes (`HH:MM`), refreshed when the minute changes. For the
  /// always-visible footer of a session that lasts hours.
  minutes(Duration.microsecondsPerMinute),

  /// Minutes and seconds (`MM:SS`), refreshed every second. For the final
  /// minute shown in the session sheet.
  seconds(Duration.microsecondsPerSecond);

  const CountdownPrecision(this.unitMicroseconds);

  /// Length of the smallest unit shown.
  final int unitMicroseconds;

  /// [remaining] rounded up to whole units, so `00:00` only shows once the
  /// session has ended.
  String format(Duration remaining) {
    final units =
        (remaining.inMicroseconds + unitMicroseconds - 1) ~/ unitMicroseconds;
    final major = (units ~/ 60).toString().padLeft(2, '0');
    final minor = (units % 60).toString().padLeft(2, '0');
    return '$major:$minor';
  }

  /// Time until the shown value next changes: the next unit boundary.
  Duration untilNextChange(Duration remaining) {
    final remainder = remaining.inMicroseconds % unitMicroseconds;
    return Duration(
      microseconds: remainder == 0 ? unitMicroseconds : remainder,
    );
  }
}
