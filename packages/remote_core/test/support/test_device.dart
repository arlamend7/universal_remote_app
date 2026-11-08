import 'package:remote_core/remote_core.dart';

RemoteDevice device(String provider) =>
    RemoteDevice(id: 'stable-id', name: 'TV', providerId: provider);
