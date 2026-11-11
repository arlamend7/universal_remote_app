import 'dart:async';

import 'package:remote_core/remote_core.dart';

import '../lifecycle/driver_package.dart';

/// A single transfer shared by callers until all of them cancel.
final class DriverPackageDownload {
  DriverPackageDownload(
    Future<DriverPackage> Function(Future<void>, void Function(double)) load,
  ) {
    _result = load(_cancelled.future, _report).whenComplete(() {
      _finished = true;
    });
  }

  final _cancelled = Completer<void>();
  final _progress = <void Function(double)>{};
  late final Future<DriverPackage> _result;
  bool _finished = false;
  int _waiters = 0;
  double? _latest;

  bool get cancelled => _cancelled.isCompleted;
  Future<DriverPackage> get result => _result;

  Future<DriverPackage> join({
    Stream<void>? cancellation,
    void Function(double)? progress,
  }) async {
    _waiters++;
    final interrupted = Completer<Never>();
    StreamSubscription<void>? listener;
    void report(double value) => progress?.call(value);
    try {
      _progress.add(report);
      final latest = _latest;
      if (latest != null) {
        report(latest);
      }
      listener = cancellation?.listen(
        (_) => _cancel(interrupted),
        onError: (Object _) => _cancel(interrupted),
      );
      return await Future.any([_result, interrupted.future]);
    } finally {
      _progress.remove(report);
      _waiters--;
      if (_waiters == 0 && !_finished && !cancelled) {
        _cancelled.complete();
      }
      await listener?.cancel();
    }
  }

  static void _cancel(Completer<Never> interrupted) {
    if (!interrupted.isCompleted) {
      interrupted.completeError(
        const RemoteException('cancelled', 'Driver download cancelled.'),
      );
    }
  }

  void _report(double progress) {
    _latest = progress;
    for (final listener in _progress.toList()) {
      listener(progress);
    }
  }
}
