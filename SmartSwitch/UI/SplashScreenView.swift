import SwiftUI

public struct SplashScreenView: View {
    @State private var isPulsing = false

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 15/255, green: 23/255, blue: 42/255),
                    Color(red: 30/255, green: 41/255, blue: 59/255),
                    Color(red: 51/255, green: 65/255, blue: 85/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .scaleEffect(isPulsing ? 1.08 : 0.92)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isPulsing
                        )

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 6) {
                    Text("SmartSwitch")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("High Speed Cross-Platform Transfer")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
                    .frame(height: 20)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}
