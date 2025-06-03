//
//  AddBoxView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 03/06/2025.
//
import SwiftUI

struct AddBoxView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var number = ""
    @State private var description = ""

    let onSave: (String, String?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Number", text: $number)
                    TextField("Description (Optional)", text: $description)
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
                        onSave(
                            number,
                            description.isEmpty ? nil : description
                        )
                    }
                    .disabled(number.isEmpty)
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
