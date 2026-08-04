import Foundation
import UIKit

public enum FileCategory: String, Codable, CaseIterable {
    case photo
    case video
    case file
    case contact
}

public struct FileItem: Identifiable, Codable, Hashable {
    public let id: String
    public let fileName: String
    public let size: Int64
    public let mimeType: String
    public let sha256: String?
    public let previewBase64: String?
    public let category: FileCategory
    public let localURL: URL?

    public init(
        id: String = UUID().uuidString,
        fileName: String,
        size: Int64,
        mimeType: String,
        sha256: String? = nil,
        previewBase64: String? = nil,
        category: FileCategory = .file,
        localURL: URL? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.size = size
        self.mimeType = mimeType
        self.sha256 = sha256
        self.previewBase64 = previewBase64
        self.category = category
        self.localURL = localURL
    }

    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct PrepareUploadRequest: Codable {
    public let info: DeviceInfo
    public let files: [String: FileMetadata]

    public struct FileMetadata: Codable {
        public let id: String
        public let fileName: String
        public let size: Int64
        public let fileType: String
        public let sha256: String?
        public let preview: String?

        public init(id: String, fileName: String, size: Int64, fileType: String, sha256: String? = nil, preview: String? = nil) {
            self.id = id
            self.fileName = fileName
            self.size = size
            self.fileType = fileType
            self.sha256 = sha256
            self.preview = preview
        }
    }

    public init(info: DeviceInfo, files: [String: FileMetadata]) {
        self.info = info
        self.files = files
    }
}

public struct PrepareUploadResponse: Codable {
    public let sessionId: String
    public let files: [String: String] // fileId -> token

    public init(sessionId: String, files: [String: String]) {
        self.sessionId = sessionId
        self.files = files
    }
}
