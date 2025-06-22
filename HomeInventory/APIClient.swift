//
//  APIClient.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 28/05/2025.
//

import Foundation

import SwiftUI

// MARK: - Models



// MARK: - API Client (Async/Await)

class APIClient {
    static let shared = APIClient()
    /// Base URL for API requests. Can be overridden by the `API_BASE_URL`
    /// environment variable to allow talking to different backends without
    /// changing code.
    private let baseURL: URL = {
        if let urlString = ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: urlString) {
            return url
        }
        return URL(string: "http://127.0.0.1:8000")!
    }()

    private let session: URLSession
    var authToken: String? // set this before calling secured endpoints

    private init() {
        let config = URLSessionConfiguration.default
        #if os(iOS)
        config.waitsForConnectivity = true
        #endif
        session = URLSession(configuration: config)
    }

    func photoURL(for filename: String) -> URL {
        baseURL.appendingPathComponent("photos").appendingPathComponent(filename)
    }

    private func makeRequest(path: String,
                             method: String = "GET",
                             body: Data? = nil,
                             contentType: String = "application/json") -> URLRequest {
        let url = URL(string: path, relativeTo: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        return request
    }


    private func request<T: Decodable>(_ path: String,
                                       method: String = "GET",
                                       body: Data? = nil,
                                       contentType: String = "application/json",
                                       decode: JSONDecoder = JSONDecoder.customISO8601)
    async throws -> T {
        let req = makeRequest(path: path, method: method, body: body, contentType: contentType)
        print(req)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return try decode.decode(T.self, from: data)
    }

    func request(method: String, path: String, body: Data? = nil) async throws {
        let url = baseURL.appendingPathComponent(path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            urlRequest.httpBody = body
        }

        let (_, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
    }


    // List all boxes
    func listBoxes() async throws -> [Box] {
        try await request("/boxes")
    }

    // Get box detail
    func getBox(_ id: Int) async throws -> BoxDetail {
        try await request("/boxes/\(id)")
    }


    struct MultipartFormDataBuilder {
        private let boundary = UUID().uuidString
        private let lineBreak = "\r\n"
        private var body = Data()

        var contentType: String {
            "multipart/form-data; boundary=\(boundary)"
        }

        mutating func appendField(name: String, value: String) {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak + lineBreak)")
            body.append("\(value)\(lineBreak)")
        }

        mutating func appendFileField(name: String, filename: String, data: Data, mimeType: String) {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\(lineBreak)")
            body.append("Content-Type: \(mimeType)\(lineBreak + lineBreak)")
            body.append(data)
            body.append(lineBreak)
        }

        func build() -> Data {
            var finalBody = body
            finalBody.append("--\(boundary)--\(lineBreak)")
            return finalBody
        }
    }


    func createBox(number: String, description: String?, photoData: Data?) async throws -> Box {
        var builder = MultipartFormDataBuilder()
        builder.appendField(name: "number", value: number)
        if let desc = description {
            builder.appendField(name: "description", value: desc)
        }
        if let data = photoData {
            builder.appendFileField(name: "photo", filename: "image.jpg", data: data, mimeType: "image/jpeg")
        }

        return try await request(
            "/boxes",
            method: "POST",
            body: builder.build(),
            contentType: builder.contentType
        )
    }

    func createItem(boxId: Int, name: String, note: String?, photoData: Data?) async throws -> Item {
        var builder = MultipartFormDataBuilder()
        builder.appendField(name: "name", value: name)
        if let note = note {
            builder.appendField(name: "note", value: note)
        }
        if let data = photoData {
            builder.appendFileField(name: "photo", filename: "image.jpg", data: data, mimeType: "image/jpeg")
        }

        return try await request(
            "/boxes/\(boxId)/items",
            method: "POST",
            body: builder.build(),
            contentType: builder.contentType
        )
    }

    // Update a box
    func updateBox(id: Int, number: String?, description: String?) async throws -> Box {
        var payload = [String: Any]()
        if let num = number { payload["number"] = num }
        if let desc = description { payload["description"] = desc }
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        return try await request("/boxes/\(id)", method: "PUT", body: data)
    }

    // Delete a box
    func deleteBox(id: Int) async throws {
        _ = try await request("/boxes/\(id)", method: "DELETE") as EmptyResponse
    }

    func searchItems(query: String) async throws -> [Item] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let path = "/search?query=\(encodedQuery)"
        return try await request(path)
    }

    func deleteBoxFromAPI(boxId: Int) async throws {
        try await request(method: "DELETE", path: "/boxes/\(boxId)")
    }
}

// Helper for empty DELETE responses
private struct EmptyResponse: Codable {}

// MARK: - JSONDecoder Extension

//private extension JSONDecoder {
//    static var iso8601: JSONDecoder {
//        let dec = JSONDecoder()
//        dec.dateDecodingStrategy = .iso8601
//        return dec
//    }
//}

// MARK: - JSONDecoder Extension with Fractional ISO8601 Support
private extension JSONDecoder {
    /// A JSONDecoder configured to parse ISO8601 date strings with fractional seconds (without timezone)
    static var customISO8601: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        // Enable parsing of date-time and fractional seconds
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            // Append 'Z' if missing timezone to satisfy formatter
            let isoString = dateString.hasSuffix("Z") ? dateString : dateString + "Z"
            guard let date = formatter.date(from: isoString) else {
                throw DecodingError.dataCorruptedError(in: container,
                    debugDescription: "Cannot decode date string \(dateString)")
            }
            return date
        }
        return decoder
    }
}

// The rest of your SwiftUI views remain unchanged, and will all work on both iOS & macOS.

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
