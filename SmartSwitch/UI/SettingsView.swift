import SwiftUI

public struct SettingsView: View {
    @ObservedObject var sessionManager: SessionManager

    public var body: some View {
        Form {
            Section(header: Text("Device Identity")) {
                HStack {
                    Text("Device Alias")
                    Spacer()
                    Text(sessionManager.myDeviceInfo.alias)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Device Model")
                    Spacer()
                    Text(sessionManager.myDeviceInfo.deviceModel)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Protocol Version")
                    Spacer()
                    Text(sessionManager.myDeviceInfo.version)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Network Status")) {
                HStack {
                    Text("Wi-Fi Connection")
                    Spacer()
                    Image(systemName: sessionManager.networkMonitor.isConnected ? "wifi" : "wifi.slash")
                        .foregroundColor(sessionManager.networkMonitor.isConnected ? .green : .red)
                    Text(sessionManager.networkMonitor.isConnected ? "Connected" : "Disconnected")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Local IP Address")
                    Spacer()
                    Text(sessionManager.networkMonitor.localIPAddress.isEmpty ? "None" : sessionManager.networkMonitor.localIPAddress)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Local Server Port")
                    Spacer()
                    Text("\(sessionManager.myDeviceInfo.port)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Security Architecture")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TLS Fingerprint (SHA-256)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(sessionManager.myDeviceInfo.fingerprint)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("Diagnostics & Troubleshooting")) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("AP / Client Isolation", systemImage: "shield.trianglebadge.exclamationmark")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("If nearby devices cannot be discovered, ensure AP Isolation or Guest Mode is disabled on your Wi-Fi router.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Port 53317 (TCP/UDP)", systemImage: "network")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("SmartSwitch uses port 53317 for HTTPS REST API and UDP Multicast announcements.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Settings & Info")
    }
}
