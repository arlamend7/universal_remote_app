import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

/// Only the state an element icon reads; every other member is unsupported.
final class MutedRemotePanel implements RemotePanel {
  MutedRemotePanel({required bool muted}) : volume = VolumeState(20, muted);
  @override
  final VolumeState? volume;
  @override
  RemoteDevice? get device => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not part of this fake',
  );
}
