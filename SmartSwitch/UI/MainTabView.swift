import SwiftUI

public struct MainTabView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var selectedTab = 0
    @State private var transferSubMode: String? = nil // nil, "send", "receive"

    public init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    public var body: some View {
        ZStack {
            if case .connected(let peer) = sessionManager.connectionStatus {
                SendView(sessionManager: sessionManager, targetPeer: peer)
            } else {
                TabView(selection: $selectedTab) {
                    DashboardView(
                        sessionManager: sessionManager,
                        onNavigateToSend: {
                            selectedTab = 1
                            transferSubMode = "send"
                        },
                        onNavigateToReceive: {
                            selectedTab = 1
                            transferSubMode = "receive"
                        }
                    )
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2.fill")
                    }
                    .tag(0)

                    Group {
                        if transferSubMode == "receive" {
                            ReceiveView(
                                sessionManager: sessionManager,
                                onBack: {
                                    selectedTab = 0
                                    transferSubMode = nil
                                }
                            )
                        } else {
                            PeerDiscoveryView(
                                sessionManager: sessionManager,
                                onBack: {
                                    selectedTab = 0
                                    transferSubMode = nil
                                }
                            )
                        }
                    }
                    .tabItem {
                        Label("Transfer", systemImage: "arrow.left.arrow.right")
                    }
                    .tag(1)

                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        .tag(2)

                    SettingsView(sessionManager: sessionManager)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(3)
                }
                .accentColor(.blue)
            }
        }
    }
}
