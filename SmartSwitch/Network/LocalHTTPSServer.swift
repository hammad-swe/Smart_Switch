import Foundation
import Network
import Combine

public protocol LocalHTTPSServerDelegate: AnyObject {
    func didReceivePrepareUpload(request: PrepareUploadRequest, completion: @escaping (Bool, PrepareUploadResponse?) -> Void)
    func didReceiveUploadChunk(sessionId: String, fileId: String, token: String, data: Data, isLastChunk: Bool, completion: @escaping (Bool) -> Void)
}

public class LocalHTTPSServer: ObservableObject {
    public let port: UInt16
    public weak var delegate: LocalHTTPSServerDelegate?

    @Published public var isRunning: Bool = false
    private var listener: NWListener?
    private let myDeviceInfo: DeviceInfo
    private var activeSessions: [String: PrepareUploadResponse] = [:]

    public init(port: UInt16 = 53317, deviceInfo: DeviceInfo) {
        self.port = port
        self.myDeviceInfo = deviceInfo
    }

    public func start() {
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true

            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        print("Local Server listening on port \(self?.port ?? 53317)")
                    case .failed(let error):
                        self?.isRunning = false
                        print("Server listener failed: \(error)")
                    case .cancelled:
                        self?.isRunning = false
                    default:
                        break
                    }
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }

            listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("Failed to start server: \(error.localizedDescription)")
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        receiveRequest(on: connection)
    }

    private func receiveRequest(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 10 * 1024 * 1024) { [weak self] data, context, isComplete, error in
            guard let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }

            self?.processHTTPData(data, connection: connection)
        }
    }

    private func processHTTPData(_ data: Data, connection: NWConnection) {
        guard let requestString = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }

        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }

        let requestComponents = firstLine.components(separatedBy: " ")
        guard requestComponents.count >= 2 else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }

        let method = requestComponents[0]
        let pathWithQuery = requestComponents[1]

        // Parse path and query parameters
        let pathComponents = pathWithQuery.components(separatedBy: "?")
        let path = pathComponents[0]
        var queryItems: [String: String] = [:]

        if pathComponents.count > 1 {
            let query = pathComponents[1]
            for item in query.components(separatedBy: "&") {
                let pair = item.components(separatedBy: "=")
                if pair.count == 2 {
                    queryItems[pair[0]] = pair[1]
                }
            }
        }

        // Locate HTTP Body
        var bodyData = Data()
        if let bodyRange = data.range(of: Data("\r\n\r\n".utf8)) {
            bodyData = data.subdata(in: bodyRange.upperBound..<data.count)
        }

        // Route Request
        switch (method, path) {
        case ("GET", "/api/localsend/v2/info"):
            handleGetInfo(connection: connection)

        case ("POST", "/api/localsend/v2/register"):
            handleRegister(connection: connection, body: bodyData)

        case ("POST", "/api/localsend/v2/prepare-upload"):
            handlePrepareUpload(connection: connection, body: bodyData)

        case ("POST", "/api/localsend/v2/upload"):
            handleUpload(connection: connection, queryItems: queryItems, body: bodyData)

        case ("POST", "/api/localsend/v2/cancel"):
            sendResponse(connection: connection, statusCode: 200, body: "{\"message\":\"Cancelled\"}")

        default:
            sendResponse(connection: connection, statusCode: 404, body: "Not Found")
        }
    }

    // MARK: - API Endpoint Handlers

    private func handleGetInfo(connection: NWConnection) {
        do {
            let responseData = try JSONEncoder().encode(myDeviceInfo)
            sendJSONResponse(connection: connection, statusCode: 200, data: responseData)
        } catch {
            sendResponse(connection: connection, statusCode: 500, body: "Internal Error")
        }
    }

    private func handleRegister(connection: NWConnection, body: Data) {
        do {
            let responseData = try JSONEncoder().encode(myDeviceInfo)
            sendJSONResponse(connection: connection, statusCode: 200, data: responseData)
        } catch {
            sendResponse(connection: connection, statusCode: 500, body: "Internal Error")
        }
    }

    private func handlePrepareUpload(connection: NWConnection, body: Data) {
        do {
            let request = try JSONDecoder().decode(PrepareUploadRequest.self, from: body)

            if let delegate = delegate {
                delegate.didReceivePrepareUpload(request: request) { [weak self] accepted, response in
                    if accepted, let response = response {
                        self?.activeSessions[response.sessionId] = response
                        if let responseData = try? JSONEncoder().encode(response) {
                            self?.sendJSONResponse(connection: connection, statusCode: 200, data: responseData)
                        } else {
                            self?.sendResponse(connection: connection, statusCode: 500, body: "Error encoding response")
                        }
                    } else {
                        self?.sendResponse(connection: connection, statusCode: 403, body: "{\"message\":\"Rejected\"}")
                    }
                }
            } else {
                // Auto-accept default for testing if delegate not attached
                let sessionId = UUID().uuidString
                var fileTokens: [String: String] = [:]
                for (_, fileMeta) in request.files {
                    fileTokens[fileMeta.id] = UUID().uuidString
                }
                let response = PrepareUploadResponse(sessionId: sessionId, files: fileTokens)
                activeSessions[sessionId] = response
                let responseData = try JSONEncoder().encode(response)
                sendJSONResponse(connection: connection, statusCode: 200, data: responseData)
            }
        } catch {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request Payload")
        }
    }

    private func handleUpload(connection: NWConnection, queryItems: [String: String], body: Data) {
        guard let sessionId = queryItems["sessionId"],
              let fileId = queryItems["fileId"],
              let token = queryItems["token"] else {
            sendResponse(connection: connection, statusCode: 400, body: "Missing parameters")
            return
        }

        if let session = activeSessions[sessionId], session.files[fileId] == token {
            delegate?.didReceiveUploadChunk(sessionId: sessionId, fileId: fileId, token: token, data: body, isLastChunk: true) { [weak self] success in
                if success {
                    self?.sendResponse(connection: connection, statusCode: 200, body: "{\"message\":\"OK\"}")
                } else {
                    self?.sendResponse(connection: connection, statusCode: 500, body: "Error saving file")
                }
            } ?? sendResponse(connection: connection, statusCode: 200, body: "{\"message\":\"OK\"}")
        } else {
            sendResponse(connection: connection, statusCode: 403, body: "Forbidden")
        }
    }

    // MARK: - Response Formatting

    private func sendResponse(connection: NWConnection, statusCode: Int, body: String) {
        let headers = "HTTP/1.1 \(statusCode) OK\r\nContent-Type: text/plain\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n"
        let fullResponse = headers + body
        connection.send(content: fullResponse.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func sendJSONResponse(connection: NWConnection, statusCode: Int, data: Data) {
        let headerString = "HTTP/1.1 \(statusCode) OK\r\nContent-Type: application/json\r\nContent-Length: \(data.count)\r\nConnection: close\r\n\r\n"
        var fullData = headerString.data(using: .utf8)!
        fullData.append(data)

        connection.send(content: fullData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
