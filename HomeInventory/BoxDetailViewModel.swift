import Foundation
import SwiftUI

class BoxDetailViewModel: ObservableObject {
    @Published var detail: BoxDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    let boxId: Int

    init(boxId: Int) {
        self.boxId = boxId
    }

    @MainActor
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
