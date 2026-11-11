import Flutter
import UIKit
import Security

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
      registerDrivers(registrar.messenger())
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

private func registerDrivers(_ messenger: FlutterBinaryMessenger) {
  let channel = FlutterMethodChannel(
    name: "br.net.devcom.universal_remote/drivers", binaryMessenger: messenger)
  channel.setMethodCallHandler { call, result in
    switch call.method {
    case "storageDirectory":
      let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      result(root?.appendingPathComponent("br.net.devcom.universalRemoteApp/remote-drivers").path)
    case "verify":
      guard let args = call.arguments as? [String: FlutterStandardTypedData],
            let key = args["key"]?.data, key.count == 65, key.first == 4,
            let payload = args["payload"]?.data, payload.count <= 4 * 1024 * 1024,
            let signature = args["signature"]?.data, signature.count <= 256 else {
        result(false)
        return
      }
      let attributes = [
        kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeyClass: kSecAttrKeyClassPublic,
        kSecAttrKeySizeInBits: 256
      ] as CFDictionary
      guard let publicKey = SecKeyCreateWithData(key as CFData, attributes, nil) else {
        result(false)
        return
      }
      result(SecKeyVerifySignature(publicKey, .ecdsaSignatureMessageX962SHA256,
                                   payload as CFData, signature as CFData, nil))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
