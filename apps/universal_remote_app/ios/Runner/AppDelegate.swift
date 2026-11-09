import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var bonjourSearches: [Int: AndroidTVBonjourSearch] = [:]

  private func registerDiscovery(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "br.net.devcom.universal_remote/discovery", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self, let id = call.arguments as? Int else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "browseAndroidTV":
        self.bonjourSearches[id]?.cancel()
        let search = AndroidTVBonjourSearch { [weak self] value in
          self?.bonjourSearches.removeValue(forKey: id)
          result(value)
        }
        self.bonjourSearches[id] = search
        search.start()
      case "cancelAndroidTV":
        self.bonjourSearches[id]?.cancel()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "UniversalRemotePreferences") {
      PreferencesChannel.register(with: registrar)
      registerDiscovery(registrar.messenger())
      let display = FlutterMethodChannel(
        name: "br.net.devcom.universal_remote/display", binaryMessenger: registrar.messenger())
      display.setMethodCallHandler { call, result in
        guard call.method == "setScreenAwake", let enabled = call.arguments as? Bool else {
          result(FlutterMethodNotImplemented)
          return
        }
        UIApplication.shared.isIdleTimerDisabled = enabled
        result(nil)
      }
    }
  }
}
