import Foundation
import Combine
import UIKit
import UserNotifications

public enum ConnectionStatus: Equatable {
    case idle
    case connecting(PeerDevice)
    case incomingRequest(PeerDevice)
    case connected(PeerDevice)

    public static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.connecting(let l), .connecting(let r)): return l.id == r.id
        case (.incomingRequest(let l), .incomingRequest(let r)): return l.id == r.id
        case (.connected(let l), .connected(let r)): return l.id == r.id
        default: return false
        }
    }
}

public class SessionManager: ObservableObject, LocalHTTPSServerDelegate {
    @Published public var networkMonitor = NetworkMonitor()
    @Published public var multicastService = MulticastService()
    @Published public var subnetScanner = SubnetScanner()
    @Published public var fileSender = FileSender()
    @Published public var fileReceiver = FileReceiver()

    @Published public var connectionStatus: ConnectionStatus = .idle
    @Published public var showTransferSummary = false
    @Published public var transferSummaryMessage = ""
    private var receivedFilesCount = 0
    @Published public var historyManager = HistoryManager.shared
    @Published public var appTheme: String = UserDefaults.standard.string(forKey: "app_theme") ?? "system" {
        didSet {
            UserDefaults.standard.set(appTheme, forKey: "app_theme")
        }
    }
    @Published public var myDeviceInfo: DeviceInfo
    @Published public var selectedPeers: [PeerDevice] = []
    @Published public var pendingIncomingRequest: PrepareUploadRequest?
    @Published public var incomingConsentCallback: ((Bool, PrepareUploadResponse?) -> Void)?

    private var server: LocalHTTPSServer?
    private var cancellables = Set<AnyCancellable>()
    private var scanTimer: Timer?

    public init() {
        let name = UIDevice.current.name
        let fingerprint = CertificateGenerator.generateFingerprint(for: "\(name)_\(Date().timeIntervalSince1970)")
        self.myDeviceInfo = DeviceInfo(alias: name, fingerprint: fingerprint)

        self.server = LocalHTTPSServer(port: UInt16(myDeviceInfo.port), deviceInfo: myDeviceInfo)
        self.server?.delegate = self

        setupBindings()
    }

    private func setupBindings() {
        // Forward changes from nested observable objects to notify SwiftUI of updates
        networkMonitor.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        multicastService.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        subnetScanner.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        fileSender.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        fileReceiver.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.startServices()
                } else {
                    self?.stopServices()
                }
            }
            .store(in: &cancellables)

        // Auto disconnect when app is closed / terminated
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.disconnect()
            }
            .store(in: &cancellables)

        // Request background execution assertion when transfer starts
        Publishers.CombineLatest(fileSender.$isSending, fileReceiver.$isReceiving)
            .receive(on: RunLoop.main)
            .sink { [weak self] isSending, isReceiving in
                if isSending || isReceiving {
                    self?.startBackgroundTask()
                } else {
                    self?.endBackgroundTask()
                }
            }
            .store(in: &cancellables)
    }

    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

    private func startBackgroundTask() {
        guard backgroundTaskId == .invalid else { return }
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "SmartSwitchTransfer") { [weak self] in
            self?.endBackgroundTask()
        }
        print("Requested background transfer assertion: \(backgroundTaskId)")
    }

    private func endBackgroundTask() {
        if backgroundTaskId != .invalid {
            print("Ending background transfer assertion: \(backgroundTaskId)")
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }

    public func startServices() {
        server?.start()
        multicastService.start(deviceInfo: myDeviceInfo)

        // Automatically trigger subnet scanner fallback on start
        scanSubnetFallback()

        // Setup a periodic timer to scan every 10 seconds to bypass multicast limits
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.scanSubnetFallback()
        }
    }

    public func stopServices() {
        scanTimer?.invalidate()
        scanTimer = nil
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
            // Auto-accept if already connected to this peer
            if case .connected(let peer) = self.connectionStatus, peer.fingerprint == request.info.fingerprint {
                let sessionId = UUID().uuidString
                var fileTokens: [String: String] = [:]
                for (fileId, _) in request.files {
                    fileTokens[fileId] = UUID().uuidString
                }
                let response = PrepareUploadResponse(sessionId: sessionId, files: fileTokens)
                self.previousRequest = request
                completion(true, response)
                return
            }

            self.pendingIncomingRequest = request
            self.incomingConsentCallback = completion
        }
    }

    public func respondToIncomingRequest(accept: Bool) {
        guard let request = pendingIncomingRequest, let callback = incomingConsentCallback else { return }

        if accept {
            self.previousRequest = request
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

    public func connect(to peer: PeerDevice) {
        self.connectionStatus = .connecting(peer)

        let scheme = peer.protocolType.lowercased() == "https" ? "https" : "http"
        guard let url = URL(string: "\(scheme)://\(peer.ip):\(peer.port)/api/localsend/v2/connect") else {
            self.connectionStatus = .idle
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0

        do {
            request.httpBody = try JSONEncoder().encode(myDeviceInfo)
        } catch {
            self.connectionStatus = .idle
            return
        }

        Task {
            do {
                let (data, response) = try await TrustManager.shared.session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    DispatchQueue.main.async {
                        self.connectionStatus = .idle
                    }
                    return
                }

                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   dict["status"] == "accepted" {
                    DispatchQueue.main.async {
                        self.connectionStatus = .connected(peer)
                        self.multicastService.stop() // Stop announcing when connected
                    }
                } else {
                    DispatchQueue.main.async {
                        self.connectionStatus = .idle
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.connectionStatus = .idle
                }
            }
        }
    }

    public func disconnect() {
        guard case .connected(let peer) = connectionStatus else { return }

        let scheme = peer.protocolType.lowercased() == "https" ? "https" : "http"
        if let url = URL(string: "\(scheme)://\(peer.ip):\(peer.port)/api/localsend/v2/disconnect") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 5.0
            Task {
                try? await TrustManager.shared.session.data(for: request)
            }
        }

        DispatchQueue.main.async {
            self.connectionStatus = .idle
            self.multicastService.start(deviceInfo: self.myDeviceInfo) // Resume announcing
        }
    }

    public func respondToConnectionRequest(accept: Bool) {
        guard case .incomingRequest(let peer) = connectionStatus,
              let callback = incomingConnectCallback else { return }

        if accept {
            self.connectionStatus = .connected(peer)
            self.multicastService.stop()
            callback(true)
        } else {
            self.connectionStatus = .idle
            callback(false)
        }

        self.incomingConnectCallback = nil
    }

    // MARK: - LocalHTTPSServerDelegate Connection Hooks

    public func didReceiveConnectRequest(peer: DeviceInfo, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let peerDevice = PeerDevice(
                alias: peer.alias,
                deviceModel: peer.deviceModel,
                deviceType: peer.deviceType,
                ip: self.networkMonitor.localIPAddress,
                port: peer.port,
                protocolType: peer.protocolType,
                fingerprint: peer.fingerprint,
                lastSeen: Date()
            )
            self.connectionStatus = .incomingRequest(peerDevice)
            self.incomingConnectCallback = completion
        }
    }

    public func didReceiveDisconnectRequest() {
        DispatchQueue.main.async {
            self.connectionStatus = .idle
            self.multicastService.start(deviceInfo: self.myDeviceInfo) // Resume announcing
        }
    }

    public func didReceiveUploadChunk(sessionId: String, fileId: String, token: String, data: Data, isLastChunk: Bool, completion: @escaping (Bool) -> Void) {
        guard let pendingReq = pendingIncomingRequest ?? previousRequest,
              let fileMeta = pendingReq.files[fileId] else {
            completion(false)
            return
        }

        DispatchQueue.main.async {
            self.fileReceiver.isReceiving = true
        }

        fileReceiver.handleIncomingFile(fileId: fileId, metadata: fileMeta, data: data) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.receivedFilesCount += 1
                    
                    self.fileReceiver.receiveProgress = Double(self.receivedFilesCount) / Double(max(pendingReq.files.count, 1))
                    self.fileReceiver.isReceiving = self.receivedFilesCount < pendingReq.files.count

                    self.sendLocalNotification(
                        title: "File Received",
                        body: "Successfully received '\(fileMeta.fileName)'"
                    )

                    self.historyManager.addRecord(
                        fileName: fileMeta.fileName,
                        fileSize: fileMeta.size,
                        isSent: false,
                        peerAlias: pendingReq.info.alias
                    )

                    if self.receivedFilesCount >= pendingReq.files.count {
                        self.transferSummaryMessage = "Successfully received \(self.receivedFilesCount) file(s)!"
                        self.showTransferSummary = true
                        self.receivedFilesCount = 0
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.fileReceiver.isReceiving = false
                }
            }
            completion(success)
        }
    }

    public func sendLocalNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }

    private var incomingConnectCallback: ((Bool) -> Void)?
    private var previousRequest: PrepareUploadRequest?
}

public struct NetworkUtils {
    public static func getSubnetPrefix(from ip: String) -> String {
        let components = ip.components(separatedBy: ".")
        guard components.count == 4 else { return "" }
        return "\(components[0]).\(components[1]).\(components[2])"
    }
}
