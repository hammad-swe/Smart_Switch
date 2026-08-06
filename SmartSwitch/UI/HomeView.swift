import SwiftUI

public struct HomeView: View {
    @StateObject private var sessionManager = SessionManager()

    public var body: some View {
        MainTabView(sessionManager: sessionManager)
            .overlay(
                ZStack {
                    if let incoming = sessionManager.pendingIncomingRequest {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        ReceiveConsentView(sessionManager: sessionManager, request: incoming)
                    }

                    if case .incomingRequest(let peer) = sessionManager.connectionStatus {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 20) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            VStack(spacing: 6) {
                                Text("Connection Request")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("\(peer.alias) wants to connect with you. Accept connection?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }

                            HStack(spacing: 16) {
                                Button(action: {
                                    sessionManager.respondToConnectionRequest(accept: false)
                                }) {
                                    Text("Decline")
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(12)
                                }

                                Button(action: {
                                    sessionManager.respondToConnectionRequest(accept: true)
                                }) {
                                    Text("Accept")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(24)
                        .background(RoundedRectangle(cornerRadius: 24).fill(Color(UIColor.systemBackground)))
                        .padding(.horizontal, 40)
                    }

                    if sessionManager.fileSender.isSending {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        TransferProgressView(
                            title: "Sending Files...",
                            progress: sessionManager.fileSender.overallProgress,
                            currentFileIndex: sessionManager.fileSender.currentFileIndex,
                            totalFiles: sessionManager.fileSender.totalFilesCount,
                            onCancel: {
                                sessionManager.fileSender.isSending = false
                            }
                        )
                        .padding(.horizontal, 40)
                    }

                    if sessionManager.fileReceiver.isReceiving {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        TransferProgressView(
                            title: "Receiving Files...",
                            progress: sessionManager.fileReceiver.receiveProgress,
                            currentFileIndex: Int(sessionManager.fileReceiver.receiveProgress * Double(sessionManager.pendingIncomingRequest?.files.count ?? 1)),
                            totalFiles: sessionManager.pendingIncomingRequest?.files.count ?? 1,
                            onCancel: {
                                sessionManager.fileReceiver.isReceiving = false
                            }
                        )
                        .padding(.horizontal, 40)
                    }

                    if sessionManager.showTransferSummary {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            VStack(spacing: 8) {
                                Text("Transfer Complete")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(sessionManager.transferSummaryMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }

                            Button(action: {
                                sessionManager.showTransferSummary = false
                            }) {
                                Text("OK")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(24)
                        .background(RoundedRectangle(cornerRadius: 24).fill(Color(UIColor.systemBackground)))
                        .padding(.horizontal, 40)
                    }
                }
            )
            .onAppear {
                requestStartupPermissions()
            }
    }

    private func requestStartupPermissions() {
        let photosManager = PhotosManager()
        photosManager.requestPermission { granted in
            print("Photos permission granted: \(granted)")
        }

        let contactsManager = ContactsManager()
        contactsManager.requestPermission { granted in
            print("Contacts permission granted: \(granted)")
        }
    }
}
