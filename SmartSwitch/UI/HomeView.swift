import SwiftUI

public struct HomeView: View {
    @StateObject private var sessionManager = SessionManager()
    @State private var selectedPeer: PeerDevice? = nil
    @State private var isShowingSettings = false

    public var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header Status Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(sessionManager.networkMonitor.isConnected ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                Text(sessionManager.networkMonitor.isConnected ? "Wi-Fi Connected" : "No Wi-Fi Network")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(sessionManager.networkMonitor.isConnected ? .green : .red)
                            }

                            if !sessionManager.networkMonitor.localIPAddress.isEmpty {
                                Text("IP: \(sessionManager.networkMonitor.localIPAddress)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(action: {
                            isShowingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color(UIColor.secondarySystemGroupedBackground)))
                    .padding(.horizontal)

                    // Hero Banner
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SmartSwitch")
                                    .font(.title)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(
                                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                    )
                                Text("iOS ↔ Android P2P File Transfer")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .padding(.horizontal)

                    // Peer Discovery Section
                    PeerDiscoveryView(sessionManager: sessionManager, selectedPeer: $selectedPeer)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedPeer) { peer in
                SendView(sessionManager: sessionManager, targetPeer: peer)
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationView {
                    SettingsView(sessionManager: sessionManager)
                }
            }
            .overlay(
                ZStack {
                    if let incoming = sessionManager.pendingIncomingRequest {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        ReceiveConsentView(sessionManager: sessionManager, request: incoming)
                    }
                }
            )
        }
    }
}
