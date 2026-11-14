import 'package:remote_core/remote_core.dart';

final class FakeApplications {
  String? launched;
  Future<String?> currentApplication() async => launched ?? 'test.youtube';
  List<DeviceApplication> installed = const [
    DeviceApplication('test.youtube', 'YouTube'),
    DeviceApplication('test.music', 'Music'),
  ];
  Future<List<DeviceApplication>> applications() async => installed;
  Future<void> launch(String id) async {
    launched = id;
  }
}
