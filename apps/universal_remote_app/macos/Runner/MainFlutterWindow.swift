import Cocoa
import FlutterMacOS
import Security

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    LocalNetworkChannel.register(with: flutterViewController.engine.binaryMessenger)
    registerDrivers(flutterViewController.engine.binaryMessenger)
    PreferencesChannel.register(with: flutterViewController.registrar(forPlugin: "UniversalRemotePreferences"))

    super.awakeFromNib()
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
