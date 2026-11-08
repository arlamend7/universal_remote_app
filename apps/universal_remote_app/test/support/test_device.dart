import 'package:remote_core/remote_core.dart';

final tv = RemoteDevice(
  id: 'stable',
  name: 'Living room',
  providerId: 'test',
  manufacturer: 'LG',
  category: DeviceCategory.television,
  endpoints: [Uri.parse('wss://192.168.1.20:3001')],
);
