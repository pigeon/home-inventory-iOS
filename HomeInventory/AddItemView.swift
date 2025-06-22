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
    @StateObject private var viewModel: AddItemViewModel

    init(boxId: Int, onDone: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddItemViewModel(boxId: boxId, onDone: onDone))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $viewModel.name)
                    TextField("Note", text: $viewModel.note)
                }
                PhotoPickerSection(photo: $viewModel.photo)
                if !viewModel.suggestedNames.isEmpty {
                    Section("Suggestions") {
                        ForEach(viewModel.suggestedNames, id: \.self) { suggestion in
                            Button(action: { viewModel.name = suggestion }) {
                                Text(suggestion)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .navigationTitle("Add Item")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            }, message: {
                if let msg = viewModel.errorMessage { Text(msg) }
            })
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
