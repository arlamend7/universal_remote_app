import 'package:remote_core/remote_core.dart';

final class FakeApplications {
  String? launched;
  Future<String?> currentApplication() async => launched ?? 'test.youtube';
  Future<List<DeviceApplication>> applications() async => const [
    DeviceApplication('test.youtube', 'YouTube'),
    DeviceApplication('test.music', 'Music'),
  ];
  Future<void> launch(String id) async {
    launched = id;
  }
}
