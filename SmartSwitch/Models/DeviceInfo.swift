import Foundation
import UIKit

public struct DeviceInfo: Codable, Equatable, Sendable {
    public let alias: String
    public let version: String
    public let deviceModel: String
    public let deviceType: String
    public let fingerprint: String
    public let port: Int
    public let protocolType: String
    public let announce: Bool?

    enum CodingKeys: String, CodingKey {
        case alias
        case version
        case deviceModel
        case deviceType
        case fingerprint
        case port
        case protocolType = "protocol"
        case announce
    }

    public init(
        alias: String = UIDevice.current.name,
        version: String = "2.0",
        deviceModel: String = UIDevice.current.model,
        deviceType: String = "mobile",
        fingerprint: String,
        port: Int = 53317,
        protocolType: String = "http",
        announce: Bool? = true
    ) {
        self.alias = alias
        self.version = version
        self.deviceModel = deviceModel
        self.deviceType = deviceType
        self.fingerprint = fingerprint
        self.port = port
        self.protocolType = protocolType
        self.announce = announce
    }
}
