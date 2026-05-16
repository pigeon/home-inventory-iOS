import Foundation
import SwiftUI

@MainActor
class BoxDetailViewModel: ObservableObject {
    @Published var detail: BoxDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    let boxId: Int

    init(boxId: Int) {
        self.boxId = boxId
    }

    func fetch() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            detail = try await APIClient.shared.getBox(boxId)
        } catch {
            errorMessage = "Error fetching box details: \(error.localizedDescription)"
        }
    }

    func refresh() {
        Task { await fetch() }
    }

    func updateBox(number: String, description: String?) async -> Bool {
        errorMessage = nil

        do {
            let updated = try await APIClient.shared.updateBox(
                id: boxId,
                number: number,
                description: description
            )
            detail = BoxDetail(
                id: updated.id,
                number: updated.number,
                description: updated.description,
                photoURL: detail?.photoURL ?? updated.photoURL,
                photoFilename: detail?.photoFilename ?? updated.photoFilename,
                createdAt: updated.createdAt,
                items: detail?.items
            )
            return true
        } catch {
            errorMessage = "Error updating box: \(error.localizedDescription)"
            return false
        }
    }

    func photoURL(for filename: String) -> URL {
        APIClient.shared.photoURL(for: filename)
    }

    var boxPhotoURL: URL? {
        if let filename = detail?.photoFilename {
            return photoURL(for: filename)
        }
        return detail?.photoURL
    }
}
