import 'package:universal_remote_app/presentation/views/remote/viewmodels/remote_viewmodel.dart';

final class DialPreviewPanel extends RemoteViewModel {
  DialPreviewPanel(super.dependencies);

  final previews = <double>[];

  @override
  void previewVolume(double value) => previews.add(value);
}
