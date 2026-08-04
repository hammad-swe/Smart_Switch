import Foundation

public struct PeerDevice: Identifiable, Hashable, Codable, Sendable {
    public var id: String { "\(ip):\(port)" }
    public let alias: String
    public let deviceModel: String
    public let deviceType: String
    public let ip: String
    public let port: Int
    public let protocolType: String
    public let fingerprint: String
    public let lastSeen: Date

    public init(
        alias: String,
        deviceModel: String,
        deviceType: String,
        ip: String,
        port: Int = 53317,
        protocolType: String = "https",
        fingerprint: String,
        lastSeen: Date = Date()
    ) {
        self.alias = alias
        self.deviceModel = deviceModel
        self.deviceType = deviceType
        self.ip = ip
        self.port = port
        self.protocolType = protocolType
        self.fingerprint = fingerprint
        self.lastSeen = lastSeen
    }
}
