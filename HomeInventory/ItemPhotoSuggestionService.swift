import Foundation
#if canImport(Vision)
import Vision
#endif
#if canImport(FoundationModels)
import FoundationModels
#endif

protocol ItemPhotoSuggestionProviding {
    func suggestions(for photoData: Data) async throws -> [String]
}

struct ItemPhotoSuggestionService: ItemPhotoSuggestionProviding {
    private static let genericTerms: Set<String> = [
        "appliance",
        "artifact",
        "container",
        "device",
        "electronic equipment",
        "equipment",
        "furniture",
        "goods",
        "home decor",
        "household appliance",
        "indoor",
        "kitchen appliance",
        "machine",
        "object",
        "product",
        "room"
    ]

    private static let blockedSuggestionTerms: Set<String> = [
        "app",
        "image",
        "inventory",
        "item",
        "items",
        "object",
        "photo",
        "picture",
        "recognition",
        "screen",
        "suggestion",
        "text",
        "ui"
    ]

    func suggestions(for photoData: Data) async throws -> [String] {
        let labels = try visionLabels(from: photoData)

        guard !labels.isEmpty else {
            return []
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *),
           case .available = SystemLanguageModel(useCase: .contentTagging).availability {
            let refined = try await refineSuggestions(with: labels)
            if !refined.isEmpty {
                return refined
            }
        }
        #endif

        return Array(labels.prefix(6))
    }

    #if canImport(Vision)
    private func visionLabels(from photoData: Data) throws -> [String] {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(data: photoData)

        try handler.perform([request])

        let observations = (request.results ?? [])
            .filter { $0.confidence >= 0.08 }
            .sorted { $0.confidence > $1.confidence }

        var preferredLabels = [String]()
        var fallbackLabels = [String]()
        var seenPreferred = Set<String>()
        var seenFallback = Set<String>()

        for observation in observations {
            let preferredCandidates = candidates(from: observation.identifier, allowGeneric: false)
            for candidate in preferredCandidates {
                guard seenPreferred.insert(candidate).inserted else { continue }
                preferredLabels.append(candidate)
                if preferredLabels.count == 8 {
                    return preferredLabels
                }
            }

            let relaxedCandidates = candidates(from: observation.identifier, allowGeneric: true)
            for candidate in relaxedCandidates {
                guard seenFallback.insert(candidate).inserted else { continue }
                fallbackLabels.append(candidate)
            }
        }

        if !preferredLabels.isEmpty {
            return preferredLabels
        }

        return Array(fallbackLabels.prefix(8))
    }
    #else
    private func visionLabels(from photoData: Data) throws -> [String] {
        _ = photoData
        return []
    }
    #endif

    private func candidates(from identifier: String, allowGeneric: Bool) -> [String] {
        identifier
            .split(separator: ",")
            .compactMap { normalize(label: String($0), allowGeneric: allowGeneric) }
    }

    private func normalize(label: String, allowGeneric: Bool = false) -> String? {
        let cleaned = label
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "/", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !cleaned.isEmpty else { return nil }

        let primaryFragment = cleaned
            .split(separator: "(")
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? cleaned

        let alphanumericOnly = primaryFragment.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) || scalar == " " ? Character(scalar) : " "
        }

        let collapsed = String(alphanumericOnly)
            .split(whereSeparator: \.isWhitespace)
            .prefix(3)
            .joined(separator: " ")

        guard !collapsed.isEmpty else { return nil }
        if !allowGeneric, Self.genericTerms.contains(collapsed) {
            return nil
        }

        if collapsed.hasSuffix("s"), !collapsed.hasSuffix("ss"), collapsed.count > 3 {
            let singular = String(collapsed.dropLast())
            if (allowGeneric || !Self.genericTerms.contains(singular)) && isValidSuggestion(singular) {
                return singular
            }
        }

        guard isValidSuggestion(collapsed) else { return nil }
        return collapsed
    }

    private func isValidSuggestion(_ suggestion: String) -> Bool {
        let words = suggestion.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return false }

        let blockedWordCount = words.filter { Self.blockedSuggestionTerms.contains($0) }.count
        if blockedWordCount > 0 {
            return false
        }

        if words.count == 1, words[0].count < 2 {
            return false
        }

        return true
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func refineSuggestions(with labels: [String]) async throws -> [String] {
        let model = SystemLanguageModel(useCase: .contentTagging)
        let session = LanguageModelSession(model: model) {
            """
            You convert image-understanding labels into concise home inventory item names.
            Return only plain text lines.
            Each line must be a short singular noun phrase.
            Prefer concrete household objects over abstract categories.
            Include multiple distinct objects only when the labels strongly imply them.
            Return between 1 and 6 suggestions.
            Do not number the lines.
            """
        }

        let response = try await session.respond(
            to: """
            Vision labels from one photo:
            \(labels.map { "- \($0)" }.joined(separator: "\n"))

            Suggest inventory item names for objects likely visible in the photo.
            """
        )

        return response.content
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                normalize(
                    label: String(line)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "-•0123456789. "))
                )
            }
            .reduce(into: [String]()) { result, candidate in
                guard !result.contains(candidate) else { return }
                result.append(candidate)
            }
    }
    #endif
}
