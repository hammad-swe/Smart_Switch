import SwiftUI

public struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    let onFinish: () -> Void

    private struct PageData {
        let title: String
        let description: String
        let icon: String
        let color: Color
    }

    private let pages = [
        PageData(
            title: "High-Speed Local Sharing",
            description: "Transfer photos, videos, contacts, and large files directly over Wi-Fi with lightning speed.",
            icon: "speedometer",
            color: .blue
        ),
        PageData(
            title: "iOS & Android Compatible",
            description: "Connect Android and iPhone devices effortlessly. Zero platform barriers or cables required.",
            icon: "arrow.triangle.2.circlepath",
            color: .purple
        ),
        PageData(
            title: "100% Offline & Private",
            description: "Your files never touch external servers or the cloud. Transfers are TLS encrypted locally.",
            icon: "lock.shield",
            color: .green
        )
    ]

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 30) {
            Spacer()

            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    let page = pages[index]
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(page.color.opacity(0.15))
                                .frame(width: 130, height: 130)

                            Image(systemName: page.icon)
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(page.color)
                        }

                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)

                            Text(page.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: 380)

            Spacer()

            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    hasCompletedOnboarding = true
                    onFinish()
                }
            }) {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .padding()
    }
}
