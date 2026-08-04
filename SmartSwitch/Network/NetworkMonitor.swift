import Foundation
import Network
import SystemConfiguration.CaptiveNetwork
import Combine

public class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "SmartSwitch.NetworkMonitor")

    @Published public var isConnected: Bool = false
    @Published public var isWiFi: Bool = false
    @Published public var localIPAddress: String = ""

    public init() {
        start()
    }

    public func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isWiFi = path.usesInterfaceType(.wifi)
                self?.localIPAddress = self?.getWiFiIPAddress() ?? ""
            }
        }
        monitor.start(queue: queue)
    }

    public func getWiFiIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            if (flags & (IFF_UP | IFF_RUNNING)) != 0 && addr.sa_family == UInt8(AF_INET) {
                let name = String(cString: ptr.pointee.ifa_name)
                if name == "en0" || name == "p2p0" { // en0 is standard Wi-Fi on iOS
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                        address = String(cString: hostname)
                        if name == "en0" { break } // Prefer en0
                    }
                }
            }
        }
        return address
    }
}
