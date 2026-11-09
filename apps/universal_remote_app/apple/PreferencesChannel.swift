import Foundation
#if os(macOS)
import FlutterMacOS
#else
import Flutter
#endif

/// Native preferences are restricted to non-secret application records.
final class PreferencesChannel: NSObject, FlutterPlugin {
  private static let allowedKeys: Set<String> = [
    "saved-devices.v2", "dashboards.v2", "settings.theme", "settings.diagnostics", "settings.accent", "settings.feedback", "settings.autoReconnect", "settings.screenAwake"
  ]
  private let defaults = UserDefaults.standard

  static func register(with registrar: FlutterPluginRegistrar) {
    #if os(macOS)
    let messenger = registrar.messenger
    #else
    let messenger = registrar.messenger()
    #endif
    let channel = FlutterMethodChannel(
      name: "br.net.devcom.universal_remote/preferences", binaryMessenger: messenger)
    registrar.addMethodCallDelegate(PreferencesChannel(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let key = arguments["key"] as? String,
          Self.allowedKeys.contains(key) else {
      result(FlutterError(code: "invalid_key", message: "Only non-secret preferences are supported.", details: nil))
      return
    }
    let nativeKey = "universal_remote.preferences.\(key)"
    switch call.method {
    case "read": result(defaults.string(forKey: nativeKey))
    case "write": write(arguments, key: nativeKey, result: result)
    case "delete": defaults.removeObject(forKey: nativeKey); result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func write(_ arguments: [String: Any], key: String, result: FlutterResult) {
    guard let value = arguments["value"] as? String else {
      result(FlutterError(code: "invalid_value", message: "A string value is required.", details: nil))
      return
    }
    defaults.set(value, forKey: key)
    result(nil)
  }
}
