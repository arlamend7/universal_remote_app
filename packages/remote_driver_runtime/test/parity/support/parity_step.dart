import 'package:remote_core/remote_core.dart';

/// One public controller call whose wire traffic and result are recorded.
final class ParityStep {
  const ParityStep(this.name, this.action);

  final String name;
  final Future<Object?> Function(TVRemoteBase remote) action;
}
