import Foundation
import SwiftUI

class AddBoxViewModel: ObservableObject {
    @Published var number: String = ""
    @Published var description: String = ""
    @Published var photo: Data?

    private let onSave: (String, String?, Data?) -> Void

    init(onSave: @escaping (String, String?, Data?) -> Void) {
        self.onSave = onSave
    }

    func save() {
        onSave(number, description.isEmpty ? nil : description, photo)
    }

    var canSave: Bool {
        !number.isEmpty
    }
}
