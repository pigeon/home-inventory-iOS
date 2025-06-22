//
//  AddBoxView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 03/06/2025.
//

import SwiftUI

/// View for adding a new box. All business logic is handled by
/// ``AddBoxViewModel`` to better follow the MVVM pattern.
struct AddBoxView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddBoxViewModel

    init(onSave: @escaping (String, String?, Data?) -> Void) {
        _viewModel = StateObject(wrappedValue: AddBoxViewModel(onSave: onSave))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Number", text: $viewModel.number)
                    TextField("Description (Optional)", text: $viewModel.description)
                }
                PhotoPickerSection(photo: $viewModel.photo)
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
#if os(iOS)
            .navigationTitle("Add Box")
#else
            .navigationTitle("Add New Box")
#endif
        }
    }
}
