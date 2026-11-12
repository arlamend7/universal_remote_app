import CoreLocation
import Network

#if os(iOS)
import Flutter
import NetworkExtension
#else
import CoreWLAN
import FlutterMacOS
#endif

final class LocalNetworkChannel: NSObject, CLLocationManagerDelegate {
  private let location = CLLocationManager()
  private var pendingPermission: FlutterResult?

  static func register(with messenger: FlutterBinaryMessenger) {
    let handler = LocalNetworkChannel()
    let channel = FlutterMethodChannel(
      name: "br.net.devcom.universal_remote/local_network", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "snapshot":
        handler.snapshot(result)
      case "requestNamePermission":
        handler.requestNamePermission(result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private override init() {
    super.init()
    location.delegate = self
  }

  private func snapshot(_ result: @escaping FlutterResult) {
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { path in
      let transport = Self.transport(for: path)
      monitor.pathUpdateHandler = nil
      monitor.cancel()
      DispatchQueue.main.async { self.readName(transport, result: result) }
    }
    monitor.start(queue: DispatchQueue.global(qos: .utility))
  }

  private static func transport(for path: Network.NWPath) -> String {
    guard path.status == .satisfied else { return "offline" }
    if path.usesInterfaceType(.wifi) { return "wifi" }
    if path.usesInterfaceType(.wiredEthernet) { return "ethernet" }
    return "offline"
  }

  private func readName(_ transport: String, result: @escaping FlutterResult) {
    guard transport == "wifi" else {
      result(["transport": transport])
      return
    }
    #if targetEnvironment(simulator)
    result(["transport": transport])
    #else
    let canRequest = location.authorizationStatus == .notDetermined
    let finish: @Sendable (String?) -> Void = { name in
      var snapshot: [String: Any] = ["transport": transport, "canRequestName": canRequest]
      if let name, !name.isEmpty { snapshot["name"] = name }
      result(snapshot)
    }
    #if os(iOS)
    NEHotspotNetwork.fetchCurrent { network in finish(network?.ssid) }
    #else
    finish(CWWiFiClient.shared().interface()?.ssid())
    #endif
    #endif
  }

  private func requestNamePermission(_ result: @escaping FlutterResult) {
    guard pendingPermission == nil, location.authorizationStatus == .notDetermined else {
      result(nil)
      return
    }
    pendingPermission = result
    location.requestWhenInUseAuthorization()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard manager.authorizationStatus != .notDetermined,
          let result = pendingPermission else { return }
    pendingPermission = nil
    result(nil)
  }
}
