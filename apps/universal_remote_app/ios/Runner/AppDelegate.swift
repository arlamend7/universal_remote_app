import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
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
