import Foundation

public struct SessionContext: Codable {
    public let sessionId: String
    public let peer: PeerDevice
    public let tokens: [String: String] // fileId -> token
    public let files: [FileItem]
    public let expectedHashes: [String: String] // fileId -> SHA256

    public init(sessionId: String, peer: PeerDevice, tokens: [String: String], files: [FileItem], expectedHashes: [String: String] = [:]) {
        self.sessionId = sessionId
        self.peer = peer
        self.tokens = tokens
        self.files = files
        self.expectedHashes = expectedHashes
    }
}
