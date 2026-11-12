import 'package:remote_core/remote_core.dart';

/// A capability's evidence and the operation set the session will use.
final class ResolvedCapability {
  const ResolvedCapability(this.evidence, [this.operations = const []]);

  final CapabilityEvidence evidence;

  /// The selected alternative; empty unless the capability is usable.
  final List<String> operations;

  bool get usable => evidence.availability.isUsable;
}
