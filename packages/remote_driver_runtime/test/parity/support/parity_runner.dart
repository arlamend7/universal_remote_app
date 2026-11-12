import 'dart:async';

import 'package:remote_core/remote_core.dart';

import 'parity_recorder.dart';
import 'parity_step.dart';
import 'parity_value.dart';

/// Runs [steps] in order and records each call's wire frames and outcome.
final class ParityRunner {
  ParityRunner(this.recorder, {this.settle = Duration.zero});

  final ParityRecorder recorder;

  /// Time for out-of-process fixtures to observe asynchronous writes.
  final Duration settle;

  Future<List<Map<String, Object?>>> run(
    TVRemoteBase remote,
    List<ParityStep> steps,
  ) async {
    final transcript = <Map<String, Object?>>[];
    for (final step in steps) {
      transcript.add(await _record(remote, step));
    }
    return transcript;
  }

  Future<Map<String, Object?>> _record(
    TVRemoteBase remote,
    ParityStep step,
  ) async {
    final outcome = await _outcome(remote, step);
    await _settle();
    return {'step': step.name, ...outcome, 'wire': recorder.drain()};
  }

  Future<Map<String, Object?>> _outcome(
    TVRemoteBase remote,
    ParityStep step,
  ) async {
    try {
      final value = await step
          .action(remote)
          .timeout(const Duration(seconds: 5));
      return {'result': parityValue(value)};
    } on RemoteException catch (error) {
      return {'error': error.code};
    } on ArgumentError {
      return {'error': 'argument'};
    } on TimeoutException {
      return {'error': 'timeout'};
    }
  }

  Future<void> _settle() async {
    for (var turn = 0; turn < 8; turn++) {
      await Future<void>.delayed(Duration.zero);
    }
    if (settle > Duration.zero) {
      await Future<void>.delayed(settle);
    }
  }
}
