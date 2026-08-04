import Foundation
import Photos
import UIKit
import PhotosUI
import Combine

public class PhotosManager: ObservableObject {
    @Published public var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published public var availablePhotos: [FileItem] = []

    public init() {
        checkPermission()
    }

    public func checkPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }

    public func requestPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                completion(status == .authorized || status == .limited)
            }
        }
    }

    public func fetchRecentPhotos(limit: Int = 50) {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = limit

            let assets = PHAsset.fetchAssets(with: options)
            var items: [FileItem] = []

            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .fastFormat

            assets.enumerateObjects { asset, _, _ in
                let resource = PHAssetResource.assetResources(for: asset).first
                let filename = resource?.originalFilename ?? "PHOTO_\(asset.localIdentifier.prefix(8)).JPG"

                // Generate small thumbnail preview
                var previewBase64: String? = nil
                imageManager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: requestOptions) { image, _ in
                    if let image = image, let jpegData = image.jpegData(compressionQuality: 0.5) {
                        previewBase64 = jpegData.base64EncodedString()
                    }
                }

                let item = FileItem(
                    id: asset.localIdentifier,
                    fileName: filename,
                    size: Int64(resource?.value(forKey: "fileSize") as? Int ?? 1024 * 1024),
                    mimeType: asset.mediaType == .video ? "video/mp4" : "image/jpeg",
                    previewBase64: previewBase64,
                    category: asset.mediaType == .video ? .video : .photo,
                    localURL: nil
                )
                items.append(item)
            }

            DispatchQueue.main.async {
                self.availablePhotos = items
            }
        }
    }

    public func savePhotoToLibrary(fileURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    public func saveVideoToLibrary(fileURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}
