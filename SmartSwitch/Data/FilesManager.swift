import Foundation
import UniformTypeIdentifiers
import Combine

public class FilesManager: ObservableObject {
    @Published public var savedFiles: [URL] = []

    public init() {
        loadSavedFiles()
    }

    public func getDownloadsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let downloads = paths[0].appendingPathComponent("SmartSwitch_Received", isDirectory: true)
        if !FileManager.default.fileExists(atPath: downloads.path) {
            try? FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        }
        return downloads
    }

    public func loadSavedFiles() {
        let dir = getDownloadsDirectory()
        do {
            let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])
            DispatchQueue.main.async {
                self.savedFiles = files
            }
        } catch {
            print("Error loading saved files: \(error)")
        }
    }

    public static func createFileItem(from url: URL) -> FileItem {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let fileName = url.lastPathComponent
        let resources = try? url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
        let size = Int64(resources?.fileSize ?? 0)
        let mimeType = resources?.contentType?.preferredMIMEType ?? "application/octet-stream"

        return FileItem(
            id: UUID().uuidString,
            fileName: fileName,
            size: size,
            mimeType: mimeType,
            category: .file,
            localURL: url
        )
    }
}
