import 'dart:convert';

import 'package:remote_core/remote_core.dart';

import 'driver_step.dart';

final class DriverCommand {
  DriverCommand._(this.steps);

  factory DriverCommand.parse(String source, DriverManifest manifest) {
    if (source.length > 16384) {
      throw const FormatException('Driver command exceeds the size limit.');
    }
    final value = jsonDecode(source);
    if (value is! List<Object?> || value.length < 3 || value.length > 32) {
      throw const FormatException('A driver command requires 3–32 steps.');
    }
    final steps = value.map(DriverStep.fromJson).toList();
    if (steps.first.operation != DriverOperation.webSocketConnect ||
        steps.last.operation != DriverOperation.webSocketDisconnect ||
        steps.skip(1).take(steps.length - 2).any(_unsupportedStep) ||
        !steps.any(
          (step) => step.operation == DriverOperation.webSocketSendJson,
        )) {
      throw const FormatException(
        'Invalid driver command connection sequence.',
      );
    }
    if (steps.any(
      (step) => !manifest.runtime.operations.contains(step.operation),
    )) {
      throw const FormatException(
        'The driver command uses an undeclared operation.',
      );
    }
    return DriverCommand._(List.unmodifiable(steps));
  }

  final List<DriverStep> steps;

  static bool _unsupportedStep(DriverStep step) =>
      step.operation != DriverOperation.webSocketSendJson &&
      step.operation != DriverOperation.webSocketAwaitJson;
}
