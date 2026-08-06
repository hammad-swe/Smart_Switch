import SwiftUI
import Photos
import Contacts

public struct ReceiveConsentView: View {
    @ObservedObject var sessionManager: SessionManager
    let request: PrepareUploadRequest

    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 6) {
                Text("Incoming Transfer Request")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("\(request.info.alias) (\(request.info.deviceModel)) wants to send \(request.files.count) file(s)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(request.files.values), id: \.id) { file in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(file.fileName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
                    }
                }
            }
            .frame(maxHeight: 180)

            HStack(spacing: 16) {
                Button(action: {
                    sessionManager.respondToIncomingRequest(accept: false)
                }) {
                    Text("Decline")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(14)
                }

                Button(action: {
                    acceptTransferWithPermissions()
                }) {
                    Text("Accept")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                        .shadow(color: .blue.opacity(0.4), radius: 6, x: 0, y: 3)
                }
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(UIColor.systemBackground)))
        .shadow(radius: 20)
        .padding(.horizontal, 20)
    }

    private func acceptTransferWithPermissions() {
        let hasMedia = request.files.values.contains { file in
            let mime = file.fileType.lowercased()
            let lowerExt = (file.fileName as NSString).pathExtension.lowercased()
            return mime.contains("image") || mime.contains("video") || ["jpg", "jpeg", "png", "heic", "mp4", "mov", "m4v"].contains(lowerExt)
        }

        let hasContacts = request.files.values.contains { file in
            let mime = file.fileType.lowercased()
            let lowerExt = (file.fileName as NSString).pathExtension.lowercased()
            return mime.contains("vcard") || lowerExt == "vcf"
        }

        func proceed() {
            DispatchQueue.main.async {
                sessionManager.respondToIncomingRequest(accept: true)
            }
        }

        if hasMedia {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                if hasContacts {
                    CNContactStore().requestAccess(for: .contacts) { _, _ in
                        proceed()
                    }
                } else {
                    proceed()
                }
            }
        } else if hasContacts {
            CNContactStore().requestAccess(for: .contacts) { _, _ in
                proceed()
            }
        } else {
            proceed()
        }
    }
}
