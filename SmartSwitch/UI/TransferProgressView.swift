import SwiftUI

public struct TransferProgressView: View {
    let title: String
    let progress: Double
    let currentFileIndex: Int
    let totalFiles: Int
    let onCancel: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                    .animation(.linear, value: progress)

                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(currentFileIndex)/\(totalFiles)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(progress >= 1.0 ? "Transfer Complete!" : "Transferring payload over local Wi-Fi...")
                    .font(.caption)
                    .foregroundColor(progress >= 1.0 ? .green : .secondary)
            }

            if progress < 1.0 {
                Button(action: onCancel) {
                    Text("Cancel Transfer")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemBackground)))
    }
}
