import 'package:remote_core/remote_core.dart';

final class FakeInputs {
  String? selected;
  Future<List<DeviceInput>> inputs() async => const [
    DeviceInput('HDMI_1', 'HDMI 1'),
    DeviceInput('HDMI_2', 'Console'),
  ];
  Future<void> selectInput(String id) async {
    selected = id;
  }
}
