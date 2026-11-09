import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var bonjourSearches: [Int: BonjourSearch] = [:]

  private func registerDiscovery(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "br.net.devcom.universal_remote/discovery", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "browseBonjour":
        guard let arguments = call.arguments as? [String: Any],
              let id = arguments["id"] as? Int,
              let service = arguments["service"] as? String,
              let declared = Bundle.main.object(forInfoDictionaryKey: "NSBonjourServices") as? [String],
              declared.contains(service) else {
          result(FlutterError(code: "bonjourUnavailable", message: nil,
                              details: ["stage": "bonjour.start"]))
          return
        }
        self.bonjourSearches[id]?.cancel()
        let search = BonjourSearch(service: service) { [weak self] value in
          self?.bonjourSearches.removeValue(forKey: id)
          result(value)
        }
        self.bonjourSearches[id] = search
        search.start()
      case "cancelBonjour":
        if let id = call.arguments as? Int { self.bonjourSearches[id]?.cancel() }
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
