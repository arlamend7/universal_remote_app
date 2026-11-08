import 'dart:async';

import 'fake_navigation.dart';
import 'fake_volume.dart';
import 'fake_current_content.dart';
import 'fake_applications.dart';
import 'fake_inputs.dart';
import 'fake_channels.dart';
import 'fake_power.dart';

import 'package:remote_core/remote_core.dart';

class FakeController extends TVRemoteBase implements DeviceWakeAddressSource {
  FakeController(
    this.device, {
    this.failure = false,
    this.startupFailure,
    this.waitPairing = false,
    this.enabledControls = false,
    this.wakeAddress,
  });
  @override
  final RemoteDevice device;
  final bool failure;
  final RemoteException? startupFailure;
  final bool waitPairing;
  final bool enabledControls;
  final String? wakeAddress;
  @override
  Future<DeviceWakeAddress?> readWakeAddress() async => wakeAddress == null
      ? null
      : DeviceWakeAddress(wakeAddress!, broadcastAddress: '192.168.1.255');
  final volumeControl = FakeVolume();
  final contentControl = FakeCurrentContent();
  final appControl = FakeApplications();
  final inputControl = FakeInputs();
  final channelControl = FakeChannels();
  final powerControl = FakePower();
  final navigationControl = FakeNavigation();
  final events = StreamController<DeviceConnectionState>.broadcast();
  final pairing = Completer<void>();
  bool disposed = false;
  @override
  DeviceConnectionState state = DeviceConnectionState.disconnected;
  @override
  Stream<DeviceConnectionState> get connectionStates => events.stream;
  @override
  List<CapabilityEvidence> get evidence => enabledControls
      ? [
          for (final capability in const [
            RemoteCapability.volume,
            RemoteCapability.absoluteVolume,
            RemoteCapability.volumeFeedback,
            RemoteCapability.mute,
            RemoteCapability.navigation,
            RemoteCapability.currentContent,
            RemoteCapability.applications,
            RemoteCapability.inputs,
            RemoteCapability.channels,
            RemoteCapability.power,
          ])
            CapabilityEvidence(
              capability,
              CapabilitySource.driver,
              CapabilityAvailability.verified,
            ),
        ]
      : [];

  T _use<T>(RemoteCapability capability, T control) {
    if (enabledControls && supports(capability)) {
      return control;
    }
    throw RemoteException('unavailable', '${capability.name} is unavailable.');
  }

  FakeVolume get _volume => _use(RemoteCapability.volume, volumeControl);
  @override
  bool get canWake => powerControl.canWake;
  @override
  Future<void> powerOff() =>
      _use(RemoteCapability.power, powerControl).powerOff();
  @override
  Future<void> wake() => powerControl.wake();
  @override
  Future<void> volumeUp() => _volume.volumeUp();
  @override
  Future<void> volumeDown() => _volume.volumeDown();
  @override
  Future<void> setVolume(int volume) => _volume.setVolume(volume);
  @override
  Future<void> setMuted(bool muted) => _volume.setMuted(muted);
  @override
  Future<VolumeState> readVolume() => _volume.readVolume();
  @override
  Stream<VolumeState> watchVolume() => _volume.watchVolume();
  @override
  Future<void> press(NavigationKey key) =>
      _use(RemoteCapability.navigation, navigationControl).press(key);
  @override
  Future<void> channelUp() =>
      _use(RemoteCapability.channels, channelControl).channelUp();
  @override
  Future<void> channelDown() =>
      _use(RemoteCapability.channels, channelControl).channelDown();
  @override
  Future<List<DeviceChannel>> channels() => _unavailable('channelSelection');
  @override
  Future<void> selectChannel(String id) => _unavailable('channelSelection');
  @override
  Future<void> sendMedia(MediaAction action) => _unavailable('media');
  @override
  Future<void> movePointer(double dx, double dy) => _unavailable('pointer');
  @override
  Future<void> scroll(double dx, double dy) => _unavailable('pointer');
  @override
  Future<void> click() => _unavailable('pointer');
  @override
  Future<void> sendKey(RemoteKey key) => _unavailable('pointer');
  @override
  Future<void> sendText(String text) => _unavailable('textInput');
  @override
  Future<void> sendEnter() => _unavailable('textInput');
  @override
  Future<List<DeviceInput>> inputs() =>
      _use(RemoteCapability.inputs, inputControl).inputs();
  @override
  Future<void> selectInput(String id) =>
      _use(RemoteCapability.inputs, inputControl).selectInput(id);
  @override
  Future<List<DeviceApplication>> applications() =>
      _use(RemoteCapability.applications, appControl).applications();
  @override
  Future<void> launchApplication(String id) =>
      _use(RemoteCapability.applications, appControl).launch(id);
  @override
  Future<String?> currentApplication() =>
      _use(RemoteCapability.applications, appControl).currentApplication();
  @override
  Future<CurrentContent> currentContent() =>
      _use(RemoteCapability.currentContent, contentControl).currentContent();
  @override
  Stream<CurrentContent> watchCurrentContent() => _use(
    RemoteCapability.currentContent,
    contentControl,
  ).watchCurrentContent();

  Future<T> _unavailable<T>(String name) =>
      Future.error(RemoteException('unavailable', '$name is unavailable.'));

  @override
  Future<void> connect() async {
    final error = startupFailure;
    if (error != null) {
      events.add(DeviceConnectionState.connecting);
      events.add(DeviceConnectionState.disconnected);
      throw error;
    }
    state = DeviceConnectionState.pairing;
    events.add(state);
    if (waitPairing) await pairing.future;
    if (failure) {
      throw const RemoteException('network', 'Test connection failed.');
    }
    state = DeviceConnectionState.connected;
    events.add(state);
  }

  @override
  Future<void> disconnect() async {
    state = DeviceConnectionState.disconnected;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    if (!pairing.isCompleted) pairing.complete();
    await contentControl.dispose();
    await events.close();
  }
}
