import Foundation

public class SelfSignedTrustSessionDelegate: NSObject, URLSessionDelegate {
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                // Bypass trust evaluation for self-signed certificates in local peer-to-peer sharing
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

public class TrustManager {
    public static let shared = TrustManager()

    public let session: URLSession

    private init() {
        let delegate = SelfSignedTrustSessionDelegate()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 3600.0 // Allow up to 1 hour for larger file transfers
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
}
