import Foundation
import Combine

public class FileSender: ObservableObject {
    @Published public var overallProgress: Double = 0.0
    @Published public var currentFileIndex: Int = 0
    @Published public var isSending: Bool = false

    public init() {}

    public func uploadFiles(
        context: SessionContext,
        onFileProgress: @escaping (String, Double) -> Void,
        onComplete: @escaping (Result<Void, TransferError>) -> Void
    ) {
        DispatchQueue.main.async {
            self.isSending = true
            self.overallProgress = 0.0
            self.currentFileIndex = 0
        }

        Task {
            let totalFiles = context.files.count
            var transferredBytes: Int64 = 0
            let totalBytes = context.files.reduce(0) { $0 + $1.size }

            for (index, file) in context.files.enumerated() {
                DispatchQueue.main.async {
                    self.currentFileIndex = index + 1
                }

                guard let token = context.tokens[file.id] else {
                    DispatchQueue.main.async {
                        onComplete(.failure(.invalidSession))
                    }
                    return
                }

                do {
                    try await self.uploadSingleFile(
                        file: file,
                        context: context,
                        token: token
                    ) { fileProgress in
                        onFileProgress(file.id, fileProgress)
                        let fileTransferred = Int64(Double(file.size) * fileProgress)
                        let currentOverall = Double(transferredBytes + fileTransferred) / Double(max(totalBytes, 1))
                        DispatchQueue.main.async {
                            self.overallProgress = currentOverall
                        }
                    }

                    transferredBytes += file.size
                } catch {
                    DispatchQueue.main.async {
                        self.isSending = false
                        if let err = error as? TransferError {
                            onComplete(.failure(err))
                        } else {
                            onComplete(.failure(.connectionFailed(error.localizedDescription)))
                        }
                    }
                    return
                }
            }

            DispatchQueue.main.async {
                self.overallProgress = 1.0
                self.isSending = false
                onComplete(.success(()))
            }
        }
    }

    private func uploadSingleFile(
        file: FileItem,
        context: SessionContext,
        token: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        guard let localURL = file.localURL, FileManager.default.fileExists(atPath: localURL.path) else {
            throw TransferError.unknown("Local file not found for \(file.fileName)")
        }

        let scheme = context.peer.protocolType.lowercased() == "https" ? "https" : "http"
        var urlComponents = URLComponents(string: "\(scheme)://\(context.peer.ip):\(context.peer.port)/api/localsend/v2/upload")
        urlComponents?.queryItems = [
            URLQueryItem(name: "sessionId", value: context.sessionId),
            URLQueryItem(name: "fileId", value: file.id),
            URLQueryItem(name: "token", value: token)
        ]

        guard let targetURL = urlComponents?.url else {
            throw TransferError.unknown("Invalid target URL")
        }

        var request = URLRequest(url: targetURL)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(String(file.size), forHTTPHeaderField: "Content-Length")

        let fileData = try Data(contentsOf: localURL, options: .mappedIfSafe)

        let (_, response) = try await URLSession.shared.upload(for: request, from: fileData)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TransferError.connectionFailed("Upload rejected by server")
        }

        progressHandler(1.0)
    }
}
