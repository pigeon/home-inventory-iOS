//
//  AddItemView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 03/06/2025.
//
import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    let boxId: Int
    var onDone: () -> Void
    @State private var name = ""
    @State private var note = ""
    @State private var photo: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Note", text: $note)
                }
                // Photo picker omitted for brevity
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        add()
                    }
                    .disabled(name.isEmpty)  // Disable save if name is empty
                }
            }
            .navigationTitle("Add Item")
        }
    }

    func add() {
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
                    dismiss()
                }
            } catch {
                print("Error adding item: \(error)")
                // Consider showing an error alert to the user
            }
        }
    }
}
