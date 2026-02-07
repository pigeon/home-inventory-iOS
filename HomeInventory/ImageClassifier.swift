import Foundation
import Vision

class ImageClassifier {
    static let shared = ImageClassifier()

    func classify(imageData: Data) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let request = VNClassifyImageRequest()
                    let handler = VNImageRequestHandler(data: imageData, options: [:])
                    try handler.perform([request])
                    let results = (request.results as? [VNClassificationObservation])?.map { $0.identifier } ?? []
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
