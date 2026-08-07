import SwiftUI

public struct ReceiveView: View {
    @ObservedObject var sessionManager: SessionManager
    var onBack: (() -> Void)? = nil
    @State private var isPulsing = false

    public init(sessionManager: SessionManager, onBack: (() -> Void)? = nil) {
        self.sessionManager = sessionManager
        self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: 30) {
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

            VStack(spacing: 6) {
                Text("Receive Mode")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Ready to accept incoming connections")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 220, height: 220)
                    .scaleEffect(isPulsing ? 1.35 : 1.0)
                    .opacity(isPulsing ? 0.0 : 0.6)
                    .animation(
                        .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: isPulsing
                    )

                Circle()
                    .fill(Color.purple)
                    .frame(width: 120, height: 120)

                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "wifi")
                        .foregroundColor(.purple)
                    Text(sessionManager.myDeviceInfo.alias)
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Text("Device IP: \(sessionManager.networkMonitor.localIPAddress.isEmpty ? "Finding..." : sessionManager.networkMonitor.localIPAddress)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Keep this screen open while the sender connects to your device.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemBackground)))

            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            isPulsing = true
        }
    }
}

