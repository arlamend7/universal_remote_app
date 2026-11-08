import 'package:remote_core/remote_core.dart';
import 'package:remote_ui/remote_ui.dart';

final class NoControllerPanelSession implements RemotePanelSession {
  const NoControllerPanelSession();

  @override
  RemoteBase? get controller => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not part of this fake',
  );
}
