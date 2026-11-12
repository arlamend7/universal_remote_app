import 'package:remote_core/remote_core.dart';

import 'parity_step.dart';
import 'parity_targets.dart';
import 'parity_value.dart';

/// Every public television member, exercised in one deterministic order.
List<ParityStep> tvParitySteps(ParityTargets targets) => [
  ParityStep('connect', (remote) => remote.connect()),
  ParityStep('evidence', (remote) async => _evidence(remote)),
  ParityStep('software', (remote) async => _software(remote)),
  ParityStep('volumeUp', (remote) => remote.volumeUp()),
  ParityStep('volumeDown', (remote) => remote.volumeDown()),
  ParityStep('readVolume', (remote) => remote.readVolume()),
  ParityStep('setVolume(25)', (remote) => remote.setVolume(25)),
  ParityStep('setVolume(101)', (remote) => remote.setVolume(101)),
  ParityStep('setMuted(true)', (remote) => remote.setMuted(true)),
  ParityStep('toggleMute', (remote) => remote.toggleMute()),
  for (final key in NavigationKey.values)
    ParityStep('press(${key.name})', (remote) => remote.press(key)),
  ParityStep('channelUp', (remote) => remote.channelUp()),
  ParityStep('channelDown', (remote) => remote.channelDown()),
  ParityStep('channels', (remote) => remote.channels()),
  ParityStep(
    'selectChannel',
    (remote) => remote.selectChannel(targets.channelId),
  ),
  for (final action in MediaAction.values)
    ParityStep(
      'sendMedia(${action.name})',
      (remote) => remote.sendMedia(action),
    ),
  ParityStep('togglePlayback', (remote) => remote.togglePlayback()),
  ParityStep('playbackState', (remote) => remote.playbackState()),
  ParityStep('turnOffScreen', (remote) => remote.turnOffScreen()),
  ParityStep('turnOnScreen', (remote) => remote.turnOnScreen()),
  ParityStep('movePointer', (remote) => remote.movePointer(3, -4)),
  ParityStep('scroll', (remote) => remote.scroll(0, 5)),
  ParityStep('click', (remote) => remote.click()),
  for (final key in RemoteKey.values)
    ParityStep('sendKey(${key.name})', (remote) => remote.sendKey(key)),
  ParityStep('sendText', (remote) => remote.sendText('abc')),
  ParityStep('sendText(empty)', (remote) => remote.sendText('')),
  ParityStep('sendEnter', (remote) => remote.sendEnter()),
  ParityStep('inputs', (remote) => remote.inputs()),
  ParityStep('selectInput', (remote) => remote.selectInput(targets.inputId)),
  ParityStep('openInputPicker', (remote) => remote.openInputPicker()),
  ParityStep('applications', (remote) => remote.applications()),
  ParityStep(
    'reportedApplicationIds',
    (remote) async => remote.reportedApplicationIds?.toList()?..sort(),
  ),
  ParityStep(
    'launchApplication',
    (remote) => remote.launchApplication(targets.applicationId),
  ),
  ParityStep(
    'launchApplication(contentId)',
    (remote) =>
        remote.launchApplication('${targets.applicationId}?contentId=42'),
  ),
  ParityStep(
    'launchApplication(web)',
    (remote) => remote.launchApplication('https://example.com/watch'),
  ),
  ParityStep('currentApplication', (remote) => remote.currentApplication()),
  ParityStep('currentContent', (remote) => remote.currentContent()),
  ParityStep('currentInput', (remote) async => remote.currentInput),
  ParityStep('bluetoothAccessories', (remote) => remote.bluetoothAccessories()),
  ParityStep(
    'toggleBluetoothAccessory',
    (remote) => remote.toggleBluetoothAccessory(targets.accessoryId),
  ),
  ParityStep(
    'openAccessorySettings',
    (remote) => remote.openAccessorySettings(),
  ),
  ParityStep('startVoiceControl', (remote) => remote.startVoiceControl()),
  ParityStep('toggleGameMode', (remote) => remote.toggleGameMode()),
  ParityStep('syncWatchCompanion', (remote) => remote.syncWatchCompanion()),
  ParityStep('canWake', (remote) async => remote.canWake),
  ParityStep('wake', (remote) => remote.wake()),
  ParityStep('powerOff', (remote) => remote.powerOff()),
  ParityStep('disconnect', (remote) => remote.disconnect()),
  ParityStep('evidence(disconnected)', (remote) async => _evidence(remote)),
];

List<String> _evidence(TVRemoteBase remote) =>
    [for (final item in remote.evidence) parityValue(item)! as String]..sort();

Map<String, Object?> _software(TVRemoteBase remote) => {
  'model': remote.device.model,
  'session': paritySoftware(remote.sessionSoftwareInformation),
};
