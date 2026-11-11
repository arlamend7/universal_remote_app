import 'package:remote_core/remote_core.dart';

RemoteDevice testDevice() => RemoteDevice(
  id: 'lg:uuid:test',
  name: 'TV',
  providerId: 'lg.webos',
  endpoints: [Uri.parse('ws://192.168.1.20:3000')],
);
