import Foundation
import Network
import Combine

public class SubnetScanner: ObservableObject {

    @Published public var isScanning: Bool = false
    @Published public var progress: Double = 0.0

    public init() {}

    public func scan(subnetPrefix: String, port: Int = 53317, onDeviceFound: @escaping (PeerDevice) -> Void) async {
        guard !subnetPrefix.isEmpty else { return }

        DispatchQueue.main.async {
            self.isScanning = true
            self.progress = 0.0
        }

        let totalHosts = 254
        var completedCount = 0

        await withTaskGroup(of: PeerDevice?.self) { group in
            for host in 1...totalHosts {
                let ip = "\(subnetPrefix).\(host)"
                group.addTask {
                    return await self.probeHost(ip: ip, port: port)
                }
            }

            for await result in group {
                completedCount += 1
                let currentProgress = Double(completedCount) / Double(totalHosts)
                DispatchQueue.main.async {
                    self.progress = currentProgress
                }

                if let peer = result {
                    DispatchQueue.main.async {
                        onDeviceFound(peer)
                    }
                }
            }
        }

        DispatchQueue.main.async {
            self.isScanning = false
        }
    }

    private func probeHost(ip: String, port: Int) async -> PeerDevice? {
        // Try HTTPS first (Android standard)
        if let peer = await tryProbe(scheme: "https", ip: ip, port: port) {
            return peer
        }
        // Fallback to HTTP (iOS standard)
        return await tryProbe(scheme: "http", ip: ip, port: port)
    }

    private func tryProbe(scheme: String, ip: String, port: Int) async -> PeerDevice? {
        guard let url = URL(string: "\(scheme)://\(ip):\(port)/api/localsend/v2/info") else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0
        request.httpMethod = "GET"

        do {
            let (data, response) = try await TrustManager.shared.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let info = try JSONDecoder().decode(DeviceInfo.self, from: data)
            return PeerDevice(
                alias: info.alias,
                deviceModel: info.deviceModel,
                deviceType: info.deviceType,
                ip: ip,
                port: info.port,
                protocolType: info.protocolType,
                fingerprint: info.fingerprint
            )
        } catch {
            return nil
        }
    }
}
