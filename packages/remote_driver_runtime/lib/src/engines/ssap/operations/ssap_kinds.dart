/// Operation kinds executed by the SSAP engine.
abstract final class SsapKinds {
  static const request = 'ssap.request';
  static const subscribe = 'ssap.subscribe';
  static const pointerOpen = 'ssap.pointer-open';
  static const pointerButton = 'ssap.pointer-button';
  static const pointerMove = 'ssap.pointer-move';
  static const pointerScroll = 'ssap.pointer-scroll';
  static const pointerClick = 'ssap.pointer-click';
  static const readContent = 'ssap.read-content';
  static const launch = 'ssap.launch';
  static const launchReported = 'ssap.launch-reported';
  static const toggleAccessory = 'ssap.toggle-accessory';
  static const identify = 'ssap.identify';
  static const wakeAddress = 'ssap.wake-address';

  static const all = {
    request,
    subscribe,
    pointerOpen,
    pointerButton,
    pointerMove,
    pointerScroll,
    pointerClick,
    readContent,
    launch,
    launchReported,
    toggleAccessory,
    identify,
    wakeAddress,
  };

  /// Typed result decoders a request or subscription may name.
  static const decoders = {
    'none',
    'volume',
    'applications',
    'inputs',
    'channels',
    'accessories',
  };
}
