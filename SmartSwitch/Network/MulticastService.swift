import Foundation
import Network
import Combine

public class MulticastService: ObservableObject {
    public static let multicastIP = "224.0.0.167"
    public static let defaultPort: UInt16 = 53317

    @Published public var discoveredPeers: [String: PeerDevice] = [:]

    private var group: NWMulticastGroup?
    private var connectionGroup: NWConnectionGroup?
    private var timer: Timer?
    private var myDeviceInfo: DeviceInfo?

    public init() {}

    public func start(deviceInfo: DeviceInfo) {
        self.myDeviceInfo = deviceInfo

        do {
            let host = NWEndpoint.Host(MulticastService.multicastIP)
            let port = NWEndpoint.Port(rawValue: MulticastService.defaultPort)!
            group = try NWMulticastGroup(for: [NWEndpoint.hostPort(host: host, port: port)])

            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            params.requiredInterfaceType = .wifi

            connectionGroup = NWConnectionGroup(with: group!, using: params)

            connectionGroup?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Multicast connection group ready on \(MulticastService.multicastIP):\(MulticastService.defaultPort)")
                case .failed(let error):
                    print("Multicast failed: \(error)")
                default:
                    break
                }
            }

            connectionGroup?.setReceiveHandler(maximumMessageSize: 65536, rejectOversizedMessages: true) { [weak self] message, content, isComplete in
                if let content = content, let peer = self?.parseAnnouncement(data: content, endpoint: message.remoteEndpoint) {
                    DispatchQueue.main.async {
                        // Don't add ourselves
                        if peer.fingerprint != self?.myDeviceInfo?.fingerprint {
                            self?.discoveredPeers[peer.id] = peer
                        }
                    }
                }
            }

            connectionGroup?.start(queue: .global(qos: .userInitiated))
            startBroadcasting()

        } catch {
            print("Failed to initialize multicast: \(error.localizedDescription)")
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        connectionGroup?.cancel()
        connectionGroup = nil
    }

    private func startBroadcasting() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.sendAnnouncement()
        }
        // Send initial announcement immediately
        sendAnnouncement()
    }

    public func sendAnnouncement() {
        guard let info = myDeviceInfo, let connectionGroup = connectionGroup else { return }

        do {
            let data = try JSONEncoder().encode(info)
            connectionGroup.send(content: data) { error in
                if let error = error {
                    print("Error broadcasting announcement: \(error)")
                }
            }
        } catch {
            print("Encoding error for announcement: \(error)")
        }
    }

    private func parseAnnouncement(data: Data, endpoint: NWEndpoint?) -> PeerDevice? {
        guard let info = try? JSONDecoder().decode(DeviceInfo.self, from: data) else {
            return nil
        }

        var ip = ""
        if case let .hostPort(host, _) = endpoint {
            switch host {
            case .ipv4(let ip4):
                ip = "\(ip4)"
            case .ipv6(let ip6):
                ip = "\(ip6)"
            default:
                break
            }
        }

        if ip.isEmpty { return nil }

        return PeerDevice(
            alias: info.alias,
            deviceModel: info.deviceModel,
            deviceType: info.deviceType,
            ip: ip,
            port: info.port,
            protocolType: info.protocolType,
            fingerprint: info.fingerprint,
            lastSeen: Date()
        )
    }
}
