import Foundation
import Contacts
import Combine

public class ContactsManager: ObservableObject {
    private let store = CNContactStore()
    @Published public var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published public var contactsCount: Int = 0

    public init() {
        checkPermission()
    }

    public func checkPermission() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }

    public func requestPermission(completion: @escaping (Bool) -> Void) {
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                self.checkPermission()
                completion(granted)
            }
        }
    }

    public func exportAllContactsToVCard(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactVCardSerialization.descriptorForRequiredKeys()
            ]

            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            var contacts: [CNContact] = []

            do {
                try self.store.enumerateContacts(with: request) { contact, _ in
                    contacts.append(contact)
                }

                let vCardData = try CNContactVCardSerialization.data(with: contacts)
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent("SmartSwitch_Contacts_\(Date().timeIntervalSince1970).vcf")
                try vCardData.write(to: fileURL)

                DispatchQueue.main.async {
                    self.contactsCount = contacts.count
                    completion(fileURL)
                }
            } catch {
                print("Failed to export contacts: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    public func importVCard(from fileURL: URL, completion: @escaping (Int, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                let contacts = try CNContactVCardSerialization.contacts(with: data)

                let saveRequest = CNSaveRequest()
                for contact in contacts {
                    let mutableContact = contact.mutableCopy() as! CNMutableContact
                    saveRequest.add(mutableContact, toContainerWithIdentifier: nil)
                }

                try self.store.execute(saveRequest)
                DispatchQueue.main.async {
                    completion(contacts.count, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(0, error)
                }
            }
        }
    }
}
