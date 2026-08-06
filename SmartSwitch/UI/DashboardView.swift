import SwiftUI

public struct DashboardView: View {
    @ObservedObject var sessionManager: SessionManager
    let onNavigateToSend: () -> Void
    let onNavigateToReceive: () -> Void

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SmartSwitch")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Seamless Cross-Platform Share")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.title)
                        .foregroundColor(.blue)
                        .padding(12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding(.top, 10)

                // Wi-Fi Status Card
                HStack(spacing: 16) {
                    Image(systemName: sessionManager.networkMonitor.isConnected ? "wifi" : "wifi.slash")
                        .font(.title2)
                        .foregroundColor(sessionManager.networkMonitor.isConnected ? .blue : .red)
                        .padding(12)
                        .background((sessionManager.networkMonitor.isConnected ? Color.blue : Color.red).opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(sessionManager.networkMonitor.isConnected ? "Connected to Local Wi-Fi" : "Wi-Fi Disconnected")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(sessionManager.networkMonitor.isConnected ? "Device IP: \(sessionManager.networkMonitor.localIPAddress.isEmpty ? "Finding..." : sessionManager.networkMonitor.localIPAddress)" : "Connect both devices to the same Wi-Fi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemBackground)))

                // Action Cards (Send & Receive)
                HStack(spacing: 16) {
                    // Send Card
                    Button(action: onNavigateToSend) {
                        VStack(alignment: .leading, spacing: 16) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())

                            Spacer()

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Send")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Connect & Share")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .frame(height: 160)
                        .background(
                            LinearGradient(colors: [.blue, Color(red: 29/255, green: 78/255, blue: 216/255)], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(24)
                    }

                    // Receive Card
                    Button(action: onNavigateToReceive) {
                        VStack(alignment: .leading, spacing: 16) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())

                            Spacer()

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Receive")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Wait Connection")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .frame(height: 160)
                        .background(
                            LinearGradient(colors: [.purple, Color(red: 109/255, green: 40/255, blue: 217/255)], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(24)
                    }
                }

                // Recent Activity Header
                HStack {
                    Text("Recent Activity")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.top, 10)

                let history = sessionManager.historyManager.historyItems
                if history.isEmpty {
                    VStack(spacing: 8) {
                        Text("No transfer history yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemBackground)))
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(history.prefix(5))) { item in
                            HStack(spacing: 14) {
                                Image(systemName: item.isSent ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(item.isSent ? .blue : .green)
                                    .padding(8)
                                    .background((item.isSent ? Color.blue : Color.green).opacity(0.15))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.fileName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    Text("\(item.isSent ? "To" : "From"): \(item.peerAlias)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("\(item.fileSize / (1024 * 1024)) MB")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemBackground)))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}
