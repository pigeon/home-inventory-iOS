import Foundation
import SwiftUI

@MainActor
class AddItemViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var note: String = ""
    @Published var photo: Data?
    @Published var errorMessage: String?
    @Published var suggestedNames: [String] = []
    @Published var selectedSuggestedNames = Set<String>()
    @Published var isAnalyzingPhoto = false
    @Published var suggestionMessage: String?

    private let boxId: Int
    private let onDone: () -> Void
    private let photoSuggestionService: ItemPhotoSuggestionProviding
    private let createItem: @Sendable (Int, String, String?, Data?) async throws -> Item
    private var suggestionTask: Task<Void, Never>?

    init(
        boxId: Int,
        onDone: @escaping () -> Void,
        photoSuggestionService: ItemPhotoSuggestionProviding = ItemPhotoSuggestionService(),
        createItem: @escaping @Sendable (Int, String, String?, Data?) async throws -> Item = { boxId, name, note, photo in
            try await APIClient.shared.createItem(boxId: boxId, name: name, note: note, photoData: photo)
        }
    ) {
        self.boxId = boxId
        self.onDone = onDone
        self.photoSuggestionService = photoSuggestionService
        self.createItem = createItem
    }

    var canSave: Bool {
        !namesToSave.isEmpty
    }

    var namesToSave: [String] {
        let selected = suggestedNames
            .filter { selectedSuggestedNames.contains($0) }
            .map(\.localizedCapitalized)
        if !selected.isEmpty {
            return selected
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? [] : [trimmed]
    }

    var primarySuggestedName: String? {
        suggestedNames.first(where: { selectedSuggestedNames.contains($0) }) ?? suggestedNames.first
    }

    func analyzePhotoSuggestions() {
        suggestionTask?.cancel()

        guard let photo else {
            suggestedNames = []
            selectedSuggestedNames = []
            suggestionMessage = nil
            isAnalyzingPhoto = false
            return
        }

        isAnalyzingPhoto = true
        suggestionMessage = nil
        suggestedNames = []
        selectedSuggestedNames = []

        suggestionTask = Task { [weak self] in
            guard let self else { return }

            do {
                let suggestions = try await photoSuggestionService.suggestions(for: photo)
                let sanitizedSuggestions = suggestions
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.isAnalyzingPhoto = false
                    self.suggestedNames = sanitizedSuggestions
                    self.selectedSuggestedNames = sanitizedSuggestions.first.map { [$0] } ?? []
                    self.suggestionMessage = sanitizedSuggestions.isEmpty ? "No suggestions found for this photo." : nil
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.isAnalyzingPhoto = false
                    self.suggestedNames = []
                    self.selectedSuggestedNames = []
                    self.suggestionMessage = "Couldn’t analyze this photo. You can still enter a custom name."
                }
            }
        }
    }

    func toggleSuggestion(_ suggestion: String) {
        if selectedSuggestedNames.contains(suggestion) {
            selectedSuggestedNames.remove(suggestion)
        } else {
            selectedSuggestedNames.insert(suggestion)
        }
    }

    func save() {
        Task {
            do {
                for suggestedName in namesToSave {
                    _ = try await createItem(
                        boxId,
                        suggestedName,
                        note.isEmpty ? nil : note,
                        photo
                    )
                }
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
