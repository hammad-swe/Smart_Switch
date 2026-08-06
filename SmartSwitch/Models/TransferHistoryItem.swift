import Foundation

public struct TransferHistoryItem: Codable, Identifiable {
    public let id: String
    public let fileName: String
    public let fileSize: Int64
    public let isSent: Bool
    public let peerAlias: String
    public let timestamp: Date

    public init(
        id: String = UUID().uuidString,
        fileName: String,
        fileSize: Int64,
        isSent: Bool,
        peerAlias: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.isSent = isSent
        self.peerAlias = peerAlias
        self.timestamp = timestamp
    }
}
