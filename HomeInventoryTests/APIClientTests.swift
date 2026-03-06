//
//  HomeInventoryTests.swift
//  HomeInventoryTests
//
//  Created by Dmytro Golub on 28/05/2025.
//

import Foundation
import XCTest
@testable import HomeInventory

final class APIClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.resetHandlers()
    }

    override func tearDown() {
        MockURLProtocol.resetHandlers()
        super.tearDown()
    }

    private func makeClient(baseURL: URL = URL(string: "http://test.local")!) -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        return APIClient(baseURL: baseURL, session: session)
    }

    func testPhotoURL_AppendsPhotosPathAndFilename() {
        let client = makeClient()
        let url = client.photoURL(for: "lamp.jpg")

        XCTAssertTrue(url.absoluteString.hasSuffix("/photos/lamp.jpg"))
    }

    func testListBoxes_WhenResponseIsValidJSON_ReturnsDecodedBoxes() async throws {
        let client = makeClient()

        MockURLProtocol.setHandler(method: "GET", path: "/boxes") { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/boxes")

            let json = """
            [
              {
                "id": 1,
                "number": "A-1",
                "description": "Garage",
                "photo_url": null,
                "photo_filename": null,
                "created_at": "2025-05-28T10:20:30.123"
              }
            ]
            """.data(using: .utf8)!

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let boxes = try await client.listBoxes()

        XCTAssertEqual(boxes.count, 1)
        XCTAssertEqual(boxes[0].id, 1)
        XCTAssertEqual(boxes[0].number, "A-1")
    }

    func testCreateItem_WhenAuthTokenAndPhotoProvided_SendsMultipartRequestWithAuthorization() async throws {
        let client = makeClient()
        client.authToken = "secret-token"

        MockURLProtocol.setHandler(method: "POST", path: "/boxes/7/items") { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/boxes/7/items")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")

            let contentType = request.value(forHTTPHeaderField: "Content-Type")
            XCTAssertNotNil(contentType)
            XCTAssertTrue(contentType?.hasPrefix("multipart/form-data; boundary=") ?? false)

            let body = request.bodyData()
            XCTAssertTrue(body.containsUTF8("name=\"name\""))
            XCTAssertTrue(body.containsUTF8("Chair"))
            XCTAssertTrue(body.containsUTF8("name=\"note\""))
            XCTAssertTrue(body.containsUTF8("Wooden"))
            XCTAssertTrue(body.containsUTF8("name=\"photo\"; filename=\"image.jpg\""))
            XCTAssertTrue(body.containsUTF8("Content-Type: image/jpeg"))

            let json = """
            {
              "id": 10,
              "box_id": 7,
              "name": "Chair",
              "note": "Wooden",
              "photo_url": null,
              "photo_filename": "image.jpg",
              "created_at": "2025-05-28T10:20:30.123"
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let item = try await client.createItem(
            boxId: 7,
            name: "Chair",
            note: "Wooden",
            photoData: Data([0x01, 0x02, 0x03])
        )

        XCTAssertEqual(item.id, 10)
        XCTAssertEqual(item.boxId, 7)
        XCTAssertEqual(item.name, "Chair")
        XCTAssertEqual(item.note, "Wooden")
    }

    func testGetBox_WhenStatusCodeIsNon2xx_ThrowsBadServerResponse() async {
        let client = makeClient()

        MockURLProtocol.setHandler(method: "GET", path: "/boxes/999") { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await client.getBox(999)
            XCTFail("Expected getBox(_:) to throw for non-2xx response")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .badServerResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeleteBoxFromAPI_SendsDeleteRequestToBoxEndpoint() async throws {
        let client = makeClient()

        MockURLProtocol.setHandler(method: "DELETE", path: "/boxes/42") { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/boxes/42")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        try await client.deleteBoxFromAPI(boxId: 42)
    }

    func testDeleteBoxFromAPI_WithBasePath_PreservesBasePath() async throws {
        let client = makeClient(baseURL: URL(string: "http://test.local/api")!)

        MockURLProtocol.setHandler(method: "DELETE", path: "/api/boxes/42") { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/api/boxes/42")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        try await client.deleteBoxFromAPI(boxId: 42)
    }

    func testSearchItems_WithBasePath_PreservesBasePathAndQuery() async throws {
        let client = makeClient(baseURL: URL(string: "http://test.local/api")!)

        MockURLProtocol.setHandler(method: "GET", path: "/api/search") { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/search")
            XCTAssertEqual(request.url?.query, "query=desk")

            let json = """
            []
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        _ = try await client.searchItems(query: "desk")
    }
}

private final class MockURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static var handlers = [String: Handler]()
    private static let lock = NSLock()

    static func setHandler(method: String, path: String, handler: @escaping Handler) {
        lock.lock()
        handlers["\(method.uppercased()) \(path)"] = handler
        lock.unlock()
    }

    static func resetHandlers() {
        lock.lock()
        handlers.removeAll()
        lock.unlock()
    }

    private static func handler(for request: URLRequest) -> Handler? {
        let method = request.httpMethod?.uppercased() ?? "GET"
        let path = request.url?.path ?? ""
        lock.lock()
        let handler = handlers["\(method) \(path)"]
        lock.unlock()
        return handler
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler(for: request) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension Data {
    func containsUTF8(_ value: String) -> Bool {
        guard let needle = value.data(using: .utf8) else {
            return false
        }
        return range(of: needle) != nil
    }
}

private extension URLRequest {
    func bodyData() -> Data {
        if let httpBody {
            return httpBody
        }

        guard let stream = httpBodyStream else {
            return Data()
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        while stream.hasBytesAvailable {
            let bytesRead = stream.read(&buffer, maxLength: bufferSize)
            if bytesRead < 0 {
                return Data()
            }
            if bytesRead == 0 {
                break
            }
            data.append(buffer, count: bytesRead)
        }

        return data
    }
}
