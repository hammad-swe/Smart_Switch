import Foundation

public enum TransferError: Error, LocalizedError {
    case networkUnavailable
    case connectionFailed(String)
    case rejectedByPeer
    case invalidSession
    case hashMismatch(fileId: String)
    case diskFull
    case cancelled
    case invalidPayload
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Wi-Fi network is unavailable. Please connect to a Wi-Fi network."
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .rejectedByPeer:
            return "The transfer request was declined by the receiver."
        case .invalidSession:
            return "Invalid or expired transfer session."
        case .hashMismatch(let fileId):
            return "File corruption detected for file ID: \(fileId) (SHA-256 hash mismatch)."
        case .diskFull:
            return "Insufficient storage space to save incoming files."
        case .cancelled:
            return "Transfer session was cancelled."
        case .invalidPayload:
            return "Received invalid network payload or corrupt headers."
        case .unknown(let msg):
            return "Transfer error: \(msg)"
        }
    }
}
