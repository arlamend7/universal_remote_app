import Darwin
import Flutter
import Network
import UIKit

/// Browses the declared Android TV service and resolves its numeric IPv4 endpoint.
final class AndroidTVBonjourSearch: NSObject, NetServiceDelegate {
  private let browser = NWBrowser(
    for: .bonjour(type: "_androidtvremote2._tcp", domain: "local."),
    using: .tcp
  )
  private let finish: FlutterResult
  private var services: [NWEndpoint: NetService] = [:]
  private var rows: [[String: Any]] = []
  private var lastResolutionError: Int?
  private var pendingResolutions = Set<ObjectIdentifier>()
  private var waitingError: NWError?
  private var deadline: DispatchWorkItem?
  private var ended = false
  private var ready = false

  init(finish: @escaping FlutterResult) {
    self.finish = finish
  }

  func start() {
    let timeout = DispatchWorkItem { [weak self] in self?.completeWindow() }
    deadline = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: timeout)
    browser.stateUpdateHandler = { [weak self] in self?.update($0) }
    browser.browseResultsChangedHandler = { [weak self] results, _ in
      self?.resolve(results)
    }
    browser.start(queue: .main)
  }

  func cancel() { end([]) }

  private func update(_ state: NWBrowser.State) {
    guard !ended else { return }
    switch state {
    case .ready:
      ready = true
      waitingError = nil
    case .waiting(let error):
      waitingError = error
      if isPolicyDenied(error) {
        end(failure(error, stage: "bonjour.browse"))
      }
    case .failed(let error):
      end(failure(error, stage: "bonjour.browse"))
    default:
      break
    }
  }

  private func isPolicyDenied(_ error: NWError) -> Bool {
    if case .dns(let code) = error { return code == -65570 }
    return false
  }

  private func failure(_ error: NWError, stage: String) -> FlutterError {
    switch error {
    case .dns(let code):
      return diagnostic(isPolicyDenied(error) ? "localNetworkDenied" : "bonjourBrowseFailed",
                        stage, "dns", Int(code))
    case .posix(let code):
      let category = [ENETDOWN, ENETUNREACH, EHOSTUNREACH].contains(code.rawValue)
        ? "networkUnreachable" : "bonjourBrowseFailed"
      return diagnostic(category, stage, "posix", Int(code.rawValue))
    case .tls(let code):
      return diagnostic("bonjourBrowseFailed", stage, "tls", Int(code))
    @unknown default:
      return diagnostic("bonjourBrowseFailed", stage, "network", nil)
    }
  }

  private func diagnostic(_ code: String, _ stage: String, _ domain: String,
                          _ number: Int?) -> FlutterError {
    var details: [String: Any] = ["stage": stage, "domain": domain]
    details["osCode"] = number
    return FlutterError(code: code, message: nil, details: details)
  }

  private func resolve(_ results: Set<NWBrowser.Result>) {
    guard !ended else { return }
    for result in results where services.count < 32 {
      guard services[result.endpoint] == nil,
            case let .service(name, type, domain, _) = result.endpoint else { continue }
      let absoluteType = type.hasSuffix(".") ? type : type + "."
      let service = NetService(domain: domain, type: absoluteType, name: name)
      pendingResolutions.insert(ObjectIdentifier(service))
      services[result.endpoint] = service
      service.delegate = self
      service.resolve(withTimeout: 1.5)
    }
  }

  func netServiceDidResolveAddress(_ sender: NetService) {
    guard !ended else { return }
    pendingResolutions.remove(ObjectIdentifier(sender))
    guard sender.port == 6466 else { return }
    guard let address = sender.addresses?.compactMap(ipv4Address).first else {
      lastResolutionError = 0
      return
    }
    rows.append(["name": sender.name, "address": address, "port": sender.port])
  }

  func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
    guard !ended else { return }
    pendingResolutions.remove(ObjectIdentifier(sender))
    lastResolutionError = errorDict[NetService.errorCode]?.intValue ?? 0
  }

  private func ipv4Address(_ data: Data) -> String? {
    guard data.count >= MemoryLayout<sockaddr_in>.size else { return nil }
    var address = sockaddr_in()
    _ = withUnsafeMutableBytes(of: &address) { data.copyBytes(to: $0) }
    guard address.sin_family == sa_family_t(AF_INET) else { return nil }
    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
    guard inet_ntop(AF_INET, &address.sin_addr, &buffer, socklen_t(buffer.count)) != nil
    else { return nil }
    return String(cString: buffer)
  }

  private func completeWindow() {
    if let error = waitingError {
      end(failure(error, stage: "bonjour.browse"))
    } else if !ready {
      end(diagnostic("responseTimeout", "bonjour.browse", "network", nil))
    } else if rows.isEmpty, let error = lastResolutionError {
      let code = error == NetService.ErrorCode.timeoutError.rawValue
        ? "responseTimeout" : "bonjourResolveFailed"
      end(diagnostic(code, "bonjour.resolve", "netService", error == 0 ? nil : error))
    } else if rows.isEmpty && !pendingResolutions.isEmpty {
      end(diagnostic("responseTimeout", "bonjour.resolve", "network", nil))
    } else {
      end(rows)
    }
  }

  private func end(_ value: Any) {
    guard !ended else { return }
    ended = true
    deadline?.cancel()
    browser.stateUpdateHandler = nil
    browser.browseResultsChangedHandler = nil
    browser.cancel()
    for service in services.values {
      service.delegate = nil
      service.stop()
    }
    services.removeAll()
    pendingResolutions.removeAll()
    finish(value)
  }
}
