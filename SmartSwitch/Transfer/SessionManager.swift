import Foundation
import Combine
import UIKit

public class SessionManager: ObservableObject, LocalHTTPSServerDelegate {
    @Published public var networkMonitor = NetworkMonitor()
    @Published public var multicastService = MulticastService()
    @Published public var subnetScanner = SubnetScanner()
    @Published public var fileSender = FileSender()
    @Published public var fileReceiver = FileReceiver()

    @Published public var myDeviceInfo: DeviceInfo
    @Published public var selectedPeers: [PeerDevice] = []
    @Published public var pendingIncomingRequest: PrepareUploadRequest?
    @Published public var incomingConsentCallback: ((Bool, PrepareUploadResponse?) -> Void)?

    private var server: LocalHTTPSServer?
    private var cancellables = Set<AnyCancellable>()

    public init() {
        let name = UIDevice.current.name
        let fingerprint = CertificateGenerator.generateFingerprint(for: "\(name)_\(Date().timeIntervalSince1970)")
        self.myDeviceInfo = DeviceInfo(alias: name, fingerprint: fingerprint)

        self.server = LocalHTTPSServer(port: UInt16(myDeviceInfo.port), deviceInfo: myDeviceInfo)
        self.server?.delegate = self

        setupBindings()
    }

    private func setupBindings() {
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.startServices()
                } else {
                    self?.stopServices()
                }
            }
            .store(in: &cancellables)
    }

    public func startServices() {
        server?.start()
        multicastService.start(deviceInfo: myDeviceInfo)
    }

    public func stopServices() {
        server?.stop()
        multicastService.stop()
    }

    public func scanSubnetFallback() {
        let prefix = NetworkUtils.getSubnetPrefix(from: networkMonitor.localIPAddress)
        guard !prefix.isEmpty else { return }

        Task {
            await subnetScanner.scan(subnetPrefix: prefix) { [weak self] peer in
                DispatchQueue.main.async {
                    self?.multicastService.discoveredPeers[peer.id] = peer
                }
            }
        }
    }

    // MARK: - LocalHTTPSServerDelegate

    public func didReceivePrepareUpload(request: PrepareUploadRequest, completion: @escaping (Bool, PrepareUploadResponse?) -> Void) {
        DispatchQueue.main.async {
            self.pendingIncomingRequest = request
            self.incomingConsentCallback = completion
        }
    }

    public func respondToIncomingRequest(accept: Bool) {
        guard let request = pendingIncomingRequest, let callback = incomingConsentCallback else { return }

        if accept {
            let sessionId = UUID().uuidString
            var fileTokens: [String: String] = [:]
            for (fileId, _) in request.files {
                fileTokens[fileId] = UUID().uuidString
            }
            let response = PrepareUploadResponse(sessionId: sessionId, files: fileTokens)
            callback(true, response)
        } else {
            callback(false, nil)
        }

        self.pendingIncomingRequest = nil
        self.incomingConsentCallback = nil
    }

    public func didReceiveUploadChunk(sessionId: String, fileId: String, token: String, data: Data, isLastChunk: Bool, completion: @escaping (Bool) -> Void) {
        guard let pendingReq = pendingIncomingRequest ?? previousRequest,
              let fileMeta = pendingReq.files[fileId] else {
            completion(false)
            return
        }

        fileReceiver.handleIncomingFile(fileId: fileId, metadata: fileMeta, data: data, completion: completion)
    }

    private var previousRequest: PrepareUploadRequest?
}

public struct NetworkUtils {
    public static func getSubnetPrefix(from ip: String) -> String {
        let components = ip.components(separatedBy: ".")
        guard components.count == 4 else { return "" }
        return "\(components[0]).\(components[1]).\(components[2])"
    }
}
