//
//  AddItemView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 03/06/2025.
//
import SwiftUI
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    let boxId: Int
    var onDone: () -> Void
    @State private var name = ""
    @State private var note = ""
    @State private var photo: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Note", text: $note)
                }
                PhotoPickerSection(photo: $photo)
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
            .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK", role: .cancel) { errorMessage = nil }
            }, message: {
                if let msg = errorMessage { Text(msg) }
            })
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
                errorMessage = "Error adding item: \(error.localizedDescription)"
            }
        }
    }
}


struct PhotoPickerSection: View {
    @Binding var photo: Data?
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        Section {
            PhotosPicker("Select Photo", selection: $selectedPhoto, matching: .images)
                .onChange(of: selectedPhoto) {
                    Task {
                        if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                            photo = data
                        }
                    }
                }

            if let photo = photo {
                #if os(iOS)
                if let uiImage = UIImage(data: photo) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: photo) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
                #endif
            }
        }
    }
}
