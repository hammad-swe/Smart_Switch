import SwiftUI

public struct PeerDiscoveryView: View {
    @ObservedObject var sessionManager: SessionManager
    @Binding var selectedPeer: PeerDevice?
    var onBack: (() -> Void)? = nil
    @State private var isPulsing = false

    public init(sessionManager: SessionManager, selectedPeer: Binding<PeerDevice?> = .constant(nil), onBack: (() -> Void)? = nil) {
        self.sessionManager = sessionManager
        self._selectedPeer = selectedPeer
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: 20) {
            if let onBack = onBack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                    Spacer()
                }
            }
            // Radar / Pulsing Animation Header
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.4 : 0.8)
                    .opacity(isPulsing ? 0.0 : 0.8)
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)

                Image(systemName: "wave.3.forward.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }

            VStack(spacing: 4) {
                Text("Searching for Devices...")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Ensure recipient is connected to the same Wi-Fi network")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Discovered Peers List
            if sessionManager.multicastService.discoveredPeers.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .padding(.top, 10)
                    Text("No nearby devices found yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        sessionManager.scanSubnetFallback()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Scan Subnet Fallback")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemBackground)))
                .padding(.horizontal)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(sessionManager.multicastService.discoveredPeers.values), id: \.id) { peer in
                            Button(action: {
                                selectedPeer = peer
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(peer.deviceType == "mobile" ? Color.indigo.opacity(0.2) : Color.green.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: peer.deviceType == "mobile" ? "iphone" : "laptopcomputer")
                                            .font(.title2)
                                            .foregroundColor(peer.deviceType == "mobile" ? .indigo : .green)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(peer.alias)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("\(peer.deviceModel) • \(peer.ip)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if case .connecting(let connectingPeer) = sessionManager.connectionStatus, connectingPeer.id == peer.id {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Button(action: {
                                            sessionManager.connect(to: peer)
                                        }) {
                                            Text("Connect")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 240)
            }
        }
    }
}
