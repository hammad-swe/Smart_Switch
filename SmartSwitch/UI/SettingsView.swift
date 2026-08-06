import SwiftUI

public struct SettingsView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var showPrivacySheet = false

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Preferences & App Information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.top, 10)

                // Appearance
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "circle.righthalf.filled")
                            .foregroundColor(.blue)
                        Text("Appearance")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }

                    Text("Choose Theme Mode")
                        .font(.subheadline)

                    Picker("Theme Mode", selection: $sessionManager.appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemBackground)))

                // Device Identity
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Device Identity")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }

                    SettingsRow(label: "Device Alias", value: sessionManager.myDeviceInfo.alias)
                    SettingsRow(label: "Device Model", value: sessionManager.myDeviceInfo.deviceModel)
                    SettingsRow(label: "Protocol Version", value: sessionManager.myDeviceInfo.version)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemBackground)))

                // Privacy & Security
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.blue)
                        Text("Security & Privacy")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }

                    Button(action: { showPrivacySheet = true }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                            Text("Privacy Policy")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("View")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemBackground)))

                // App Information
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "app.badge")
                            .foregroundColor(.blue)
                        Text("About App")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }

                    SettingsRow(label: "Application Version", value: "SmartSwitch v2.1.0")
                    SettingsRow(label: "Build Engine", value: "LocalSend Protocol v2")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemBackground)))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showPrivacySheet) {
            VStack(spacing: 20) {
                Text("Privacy Policy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("SmartSwitch operates completely offline on your local Wi-Fi network.\n\n• No files or data are uploaded to external cloud servers.\n• File transfers are encrypted point-to-point using TLS certificates.\n• Connections require explicit user consent.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding()

                Spacer()

                Button(action: { showPrivacySheet = false }) {
                    Text("Close")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

private struct SettingsRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
