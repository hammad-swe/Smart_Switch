import Foundation
import UIKit
import Combine

public class FileReceiver: ObservableObject {
    @Published public var incomingRequest: PrepareUploadRequest?
    @Published public var isReceiving: Bool = false
    @Published public var receiveProgress: Double = 0.0

    private let filesManager = FilesManager()
    private let photosManager = PhotosManager()
    private let contactsManager = ContactsManager()

    public init() {}

    public func handleIncomingFile(
        fileId: String,
        metadata: PrepareUploadRequest.FileMetadata,
        data: Data,
        completion: @escaping (Bool) -> Void
    ) {
        let downloadsDir = filesManager.getDownloadsDirectory()
        let destURL = downloadsDir.appendingPathComponent(metadata.fileName)

        do {
            try data.write(to: destURL)

            // Hash verification if present
            if let expectedHash = metadata.sha256 {
                let actualHash = try CertificateGenerator.sha256(of: destURL)
                if actualHash.lowercased() != expectedHash.lowercased() {
                    print("SHA256 mismatch for \(metadata.fileName)")
                    completion(false)
                    return
                }
            }

            // Route based on file type
            let lowerExt = destURL.pathExtension.lowercased()
            let mime = metadata.fileType.lowercased()

            if mime.contains("image") || ["jpg", "jpeg", "png", "heic"].contains(lowerExt) {
                photosManager.savePhotoToLibrary(fileURL: destURL) { _, _ in }
            } else if mime.contains("video") || ["mp4", "mov", "m4v"].contains(lowerExt) {
                photosManager.saveVideoToLibrary(fileURL: destURL) { _, _ in }
            } else if mime.contains("vcard") || lowerExt == "vcf" {
                contactsManager.importVCard(from: destURL) { _, _ in }
            }

            completion(true)
        } catch {
            print("Error saving received file: \(error)")
            completion(false)
        }
    }
}
