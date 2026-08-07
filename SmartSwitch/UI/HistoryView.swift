import SwiftUI

public struct HistoryView: View {
    @ObservedObject var historyManager = HistoryManager.shared
    @State private var selectedFilter = 0 // 0: All, 1: Sent, 2: Received
    @State private var previewItem: URLItem? = nil

    private struct URLItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    private var filteredItems: [TransferHistoryItem] {
        switch selectedFilter {
        case 1:
            return historyManager.historyItems.filter { $0.isSent }
        case 2:
            return historyManager.historyItems.filter { !$0.isSent }
        default:
            return historyManager.historyItems
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Transfer History")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("\(historyManager.historyItems.count) transfer record(s)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()

                if !historyManager.historyItems.isEmpty {
                    Button(action: {
                        historyManager.clearHistory()
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .padding(10)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.top, 10)

            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag(0)
                Text("Sent").tag(1)
                Text("Received").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())

            if filteredItems.isEmpty {
                Spacer()
                Text("No history records found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredItems) { item in
                            Button(action: {
                                let downloads = FilesManager.shared.getDownloadsDirectory()
                                let targetURL = downloads.appendingPathComponent(item.fileName)
                                if FileManager.default.fileExists(atPath: targetURL.path) {
                                    previewItem = URLItem(url: targetURL)
                                }
                            }) {
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
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Text("\(item.isSent ? "To" : "From"): \(item.peerAlias) • \(item.timestamp, formatter: dateFormatter)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(FormatUtils.formatFileSize(item.fileSize))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemBackground)))
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .padding(.horizontal, 20)
        .sheet(item: $previewItem) { item in
            QuickLookPreview(url: item.url)
        }
    }
}
