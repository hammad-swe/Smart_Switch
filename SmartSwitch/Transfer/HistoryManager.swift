import Foundation
import Combine

public class HistoryManager: ObservableObject {
    public static let shared = HistoryManager()
    private let userDefaultsKey = "smartswitch_transfer_history"

    @Published public var historyItems: [TransferHistoryItem] = []

    public init() {
        loadHistory()
    }

    public func addRecord(fileName: String, fileSize: Int64, isSent: Bool, peerAlias: String) {
        let newItem = TransferHistoryItem(
            fileName: fileName,
            fileSize: fileSize,
            isSent: isSent,
            peerAlias: peerAlias
        )
        DispatchQueue.main.async {
            self.historyItems.insert(newItem, at: 0)
            self.saveHistory()
        }
    }

    public func clearHistory() {
        DispatchQueue.main.async {
            self.historyItems.removeAll()
            UserDefaults.standard.removeObject(forKey: self.userDefaultsKey)
        }
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(historyItems) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([TransferHistoryItem].self, from: data) {
            self.historyItems = decoded
        }
    }
}
