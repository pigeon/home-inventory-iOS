import XCTest
@testable import HomeInventory

@MainActor
final class AddItemViewModelTests: XCTestCase {
    func testNamesToSave_UsesSelectedSuggestionsBeforeCustomName() {
        let viewModel = AddItemViewModel(boxId: 1, onDone: {})

        viewModel.name = "Custom Lamp"
        viewModel.suggestedNames = ["lamp", "chair"]
        viewModel.selectedSuggestedNames = ["chair"]

        XCTAssertEqual(viewModel.namesToSave, ["Chair"])
        XCTAssertTrue(viewModel.canSave)
    }

    func testNamesToSave_FallsBackToCustomNameWhenNoSuggestionSelected() {
        let viewModel = AddItemViewModel(boxId: 1, onDone: {})

        viewModel.name = "Desk"

        XCTAssertEqual(viewModel.namesToSave, ["Desk"])
        XCTAssertTrue(viewModel.canSave)
    }

    func testSave_CreatesOneItemPerSelectedSuggestion() async {
        let recorder = SaveRecorder()

        let viewModel = AddItemViewModel(
            boxId: 7,
            onDone: { Task { await recorder.recordOnDone() } },
            createItem: { _, name, _, _ in
                await recorder.recordCreatedName(name)
                return Item(
                    id: 1,
                    boxId: 7,
                    name: name,
                    note: nil,
                    photoURL: nil,
                    photoFilename: nil,
                    createdAt: .init()
                )
            }
        )

        viewModel.suggestedNames = ["chair", "table", "lamp"]
        viewModel.selectedSuggestedNames = ["table", "lamp"]
        viewModel.save()

        let expectation = expectation(description: "save completes")
        Task {
            while await recorder.createdNames.count < 2 || await recorder.onDoneCallCount < 1 {
                try? await Task.sleep(for: .milliseconds(10))
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(await recorder.createdNames, ["table", "lamp"])
        XCTAssertEqual(await recorder.onDoneCallCount, 1)
    }

    func testAnalyzePhotoSuggestions_AutoSelectsTopSuggestion() async {
        let viewModel = AddItemViewModel(
            boxId: 1,
            onDone: {},
            photoSuggestionService: MockPhotoSuggestionService(result: .success(["lamp", "table"]))
        )

        viewModel.photo = Data([0x01])
        viewModel.analyzePhotoSuggestions()

        let expectation = expectation(description: "analysis completes")
        Task {
            while viewModel.isAnalyzingPhoto {
                try? await Task.sleep(for: .milliseconds(10))
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.suggestedNames, ["lamp", "table"])
        XCTAssertEqual(viewModel.selectedSuggestedNames, ["lamp"])
        XCTAssertEqual(viewModel.namesToSave, ["Lamp"])
    }
}

private actor SaveRecorder {
    private(set) var createdNames = [String]()
    private(set) var onDoneCallCount = 0

    func recordCreatedName(_ name: String) {
        createdNames.append(name)
    }

    func recordOnDone() {
        onDoneCallCount += 1
    }
}

private struct MockPhotoSuggestionService: ItemPhotoSuggestionProviding {
    let result: Result<[String], Error>

    func suggestions(for photoData: Data) async throws -> [String] {
        _ = photoData
        return try result.get()
    }
}
