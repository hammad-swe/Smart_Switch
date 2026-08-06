import Foundation

public class TransferSession {
    public static let shared = TransferSession()

    private init() {}

    public func prepareUpload(
        files: [FileItem],
        myDeviceInfo: DeviceInfo,
        to peer: PeerDevice
    ) async throws -> SessionContext {
        let scheme = peer.protocolType.lowercased() == "https" ? "https" : "http"
        guard let url = URL(string: "\(scheme)://\(peer.ip):\(peer.port)/api/localsend/v2/prepare-upload") else {
            throw TransferError.unknown("Invalid target URL")
        }

        var fileMetadataMap: [String: PrepareUploadRequest.FileMetadata] = [:]
        var fileItemsMap: [String: FileItem] = [:]

        for file in files {
            fileMetadataMap[file.id] = PrepareUploadRequest.FileMetadata(
                id: file.id,
                fileName: file.fileName,
                size: file.size,
                fileType: file.mimeType,
                sha256: file.sha256,
                preview: file.previewBase64
            )
            fileItemsMap[file.id] = file
        }

        let requestPayload = PrepareUploadRequest(info: myDeviceInfo, files: fileMetadataMap)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15.0

        do {
            request.httpBody = try JSONEncoder().encode(requestPayload)
        } catch {
            throw TransferError.invalidPayload
        }

        let (data, response) = try await TrustManager.shared.session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TransferError.connectionFailed("No HTTP response")
        }

        if httpResponse.statusCode == 403 {
            throw TransferError.rejectedByPeer
        }

        guard httpResponse.statusCode == 200 else {
            throw TransferError.connectionFailed("HTTP Status \(httpResponse.statusCode)")
        }

        do {
            let prepareResponse = try JSONDecoder().decode(PrepareUploadResponse.self, from: data)
            var expectedHashes: [String: String] = [:]
            for file in files {
                if let hash = file.sha256 {
                    expectedHashes[file.id] = hash
                }
            }

            return SessionContext(
                sessionId: prepareResponse.sessionId,
                peer: peer,
                tokens: prepareResponse.files,
                files: files,
                expectedHashes: expectedHashes
            )
        } catch {
            throw TransferError.invalidPayload
        }
    }
}
