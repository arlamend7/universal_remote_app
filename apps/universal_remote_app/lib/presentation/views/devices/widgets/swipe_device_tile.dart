import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../viewmodels/devices_viewmodel.dart';
import 'swipe_device_tile_state.dart';

class SwipeDeviceTile extends StatefulWidget {
  const SwipeDeviceTile({super.key, required this.model, required this.device});

  final DevicesViewModel model;
  final RemoteDevice device;

  @override
  State<SwipeDeviceTile> createState() => SwipeDeviceTileState();
}
