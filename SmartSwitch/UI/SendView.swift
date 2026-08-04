import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

public struct SendView: View {
    @ObservedObject var sessionManager: SessionManager
    let targetPeer: PeerDevice

    @StateObject private var photosManager = PhotosManager()
    @StateObject private var contactsManager = ContactsManager()

    @State private var selectedItems: [FileItem] = []
    @State private var isShowingFilePicker = false
    @State private var isExportingContacts = false
    @State private var isTransferring = false
    @State private var transferError: String? = nil
    @State private var activeSessionContext: SessionContext? = nil

    public var body: some View {
        VStack(spacing: 16) {
            // Header with target peer info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sending to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(targetPeer.alias)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemBackground)))

            // Categories Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button(action: {
                        photosManager.fetchRecentPhotos()
                    }) {
                        Label("Photos & Videos", systemImage: "photo.on.rectangle.angled")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(20)
                    }

                    Button(action: {
                        isShowingFilePicker = true
                    }) {
                        Label("Files", systemImage: "doc.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(20)
                    }

                    Button(action: {
                        exportContacts()
                    }) {
                        Label("Contacts", systemImage: "person.crop.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(20)
                    }
                }
            }

            // Photos Grid Selection
            if !photosManager.availablePhotos.isEmpty {
                VStack(alignment: .leading) {
                    Text("Recent Photos (\(photosManager.availablePhotos.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(photosManager.availablePhotos) { photo in
                                ZStack(alignment: .topTrailing) {
                                    if let base64 = photo.previewBase64,
                                       let data = Data(base64Encoded: base64),
                                       let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 80, height: 80)
                                    }

                                    let isSelected = selectedItems.contains(where: { $0.id == photo.id })
                                    Circle()
                                        .fill(isSelected ? Color.blue : Color.black.opacity(0.4))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: isSelected ? "checkmark" : "")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        )
                                        .padding(4)
                                }
                                .onTapGesture {
                                    if let idx = selectedItems.firstIndex(where: { $0.id == photo.id }) {
                                        selectedItems.remove(at: idx)
                                    } else {
                                        selectedItems.append(photo)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }

            // Selected Items List
            if !selectedItems.isEmpty {
                VStack(alignment: .leading) {
                    Text("Selected Items (\(selectedItems.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(selectedItems) { item in
                                HStack {
                                    Image(systemName: item.category == .photo ? "photo" : item.category == .contact ? "person.crop.circle" : "doc")
                                        .foregroundColor(.blue)
                                    Text(item.fileName)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button(action: {
                                        selectedItems.removeAll(where: { $0.id == item.id })
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                }
            }

            Spacer()

            if let err = transferError {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // Transfer Action Button
            Button(action: {
                startTransfer()
            }) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Transfer \(selectedItems.count) Item(s)")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .disabled(selectedItems.isEmpty || isTransferring)
            .opacity(selectedItems.isEmpty ? 0.5 : 1.0)
        }
        .padding()
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                for url in urls {
                    let item = FilesManager.createFileItem(from: url)
                    selectedItems.append(item)
                }
            }
        }
    }

    private func exportContacts() {
        contactsManager.requestPermission { granted in
            if granted {
                contactsManager.exportAllContactsToVCard { fileURL in
                    if let url = fileURL {
                        let item = FilesManager.createFileItem(from: url)
                        selectedItems.append(item)
                    }
                }
            }
        }
    }

    private func startTransfer() {
        isTransferring = true
        transferError = nil

        Task {
            do {
                let context = try await TransferSession.shared.prepareUpload(
                    files: selectedItems,
                    myDeviceInfo: sessionManager.myDeviceInfo,
                    to: targetPeer
                )

                DispatchQueue.main.async {
                    self.activeSessionContext = context
                }

                sessionManager.fileSender.uploadFiles(context: context, onFileProgress: { _, _ in }) { result in
                    DispatchQueue.main.async {
                        self.isTransferring = false
                        switch result {
                        case .success:
                            self.selectedItems.removeAll()
                        case .failure(let err):
                            self.transferError = err.localizedDescription
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isTransferring = false
                    self.transferError = error.localizedDescription
                }
            }
        }
    }
}
