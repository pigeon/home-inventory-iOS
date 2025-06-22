import Foundation
import SwiftUI

class AddItemViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var note: String = ""
    @Published var photo: Data?
    @Published var errorMessage: String?

    private let boxId: Int
    private let onDone: () -> Void

    init(boxId: Int, onDone: @escaping () -> Void) {
        self.boxId = boxId
        self.onDone = onDone
    }

    var canSave: Bool {
        !name.isEmpty
    }

    func save() {
        Task {
            do {
                _ = try await APIClient.shared.createItem(
                    boxId: boxId,
                    name: name,
                    note: note.isEmpty ? nil : note,
                    photoData: photo
                )
                await MainActor.run {
                    onDone()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error adding item: \(error.localizedDescription)"
                }
            }
        }
    }
}
