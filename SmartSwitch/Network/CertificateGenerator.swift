import Foundation
import Security
import CryptoKit

public class CertificateGenerator {

    /// Generates a SHA-256 fingerprint for a given String or device identifier
    public static func generateFingerprint(for identifier: String) -> String {
        let inputData = Data(identifier.utf8)
        let hash = SHA256.hash(data: inputData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Helper to compute SHA-256 of Data
    public static func sha256(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Helper to compute SHA-256 of file at URL
    public static func sha256(of fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        var hasher = SHA256()
        while case let buffer = handle.readData(ofLength: 64 * 1024), !buffer.isEmpty {
            hasher.update(data: buffer)
        }
        let digest = hasher.finalize()
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
