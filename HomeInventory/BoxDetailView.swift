//
//  BoxDetailView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 03/06/2025.
//

import SwiftUI

struct BoxDetailView: View {
    @StateObject private var viewModel: BoxDetailViewModel
    @State private var addItem = false
    @State private var editBox = false

    init(boxId: Int) {
        _viewModel = StateObject(wrappedValue: BoxDetailViewModel(boxId: boxId))
    }

    var body: some View {
        List {
            if let detail = viewModel.detail {
                if let url = viewModel.boxPhotoURL {
                    Section {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediaCornerRadius, style: .continuous))
                        } placeholder: {
                            ProgressView()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.appSurface)
                }
                Section {
                    Text("Number: \(detail.number)")
                        .foregroundStyle(Color.appTextPrimary)
                    if let description = detail.description {
                        Text(description)
                            .foregroundStyle(Color.appTextPrimary)
                    }
                }
                .listRowBackground(Color.appSurface)

                Section {
                    ForEach(detail.items ?? []) { item in
                        NavigationLink {
                            ItemDetailView(item: item, boxNumber: detail.number)
                        } label: {
                            HStack(alignment: .top, spacing: 8) {
                                if let filename = item.photoFilename {
                                    AsyncImage(url: viewModel.photoURL(for: filename)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediaCornerRadius, style: .continuous))
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 60, height: 60)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .foregroundStyle(Color.appTextPrimary)
                                    if let note = item.note {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(Color.appTextSecondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.appSurface)
                    }
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.appBackground)
            } else {
                Text("Error loading box details")
                    .foregroundStyle(Color.appError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.appSurfaceSecondary)
            }
        }
        .navigationTitle("Box Details")
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(Color.appPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.detail != nil {
                    Button {
                        editBox = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .foregroundStyle(Color.appPrimary)
                    .accessibilityLabel("Edit Box")
                }
            }
        }
        .sheet(isPresented: $addItem) {
            AddItemView(boxId: viewModel.boxId, onDone: refresh)
        }
        .sheet(isPresented: $editBox) {
            if let detail = viewModel.detail {
                EditBoxView(
                    number: detail.number,
                    description: detail.description,
                    onSave: { number, description in
                        let didSave = await viewModel.updateBox(number: number, description: description)
                        if didSave {
                            editBox = false
                        }
                    }
                )
            }
        }
        .task {
            await viewModel.fetch()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        }, message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        })
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }

    private func refresh() {
        addItem = false
        Task {
            await viewModel.fetch()
        }
    }
}

private struct EditBoxView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditBoxViewModel

    init(
        number: String,
        description: String?,
        onSave: @escaping @MainActor (String, String?) async -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: EditBoxViewModel(
                number: number,
                description: description ?? "",
                onSave: onSave
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Number", text: $viewModel.number)
                    TextField("Description (Optional)", text: $viewModel.description)
                }
                .listRowBackground(Color.appSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.appTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isSaving ? "Saving..." : "Save") {
                        viewModel.save()
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                    .foregroundStyle(viewModel.canSave ? Color.appPrimary : Color.appTextSecondary)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .navigationTitle("Edit Box")
        }
    }
}

@MainActor
private final class EditBoxViewModel: ObservableObject {
    @Published var number: String
    @Published var description: String
    @Published var isSaving = false

    private let onSave: @MainActor (String, String?) async -> Void

    init(
        number: String,
        description: String,
        onSave: @escaping @MainActor (String, String?) async -> Void
    ) {
        self.number = number
        self.description = description
        self.onSave = onSave
    }

    var canSave: Bool {
        !number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() {
        guard canSave, !isSaving else { return }

        isSaving = true
        Task {
            await onSave(
                number.trimmingCharacters(in: .whitespacesAndNewlines),
                description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : description.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isSaving = false
        }
    }
}
