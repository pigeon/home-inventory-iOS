//
//  Objects.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 28/05/2025.
//

import Foundation

struct Box: Identifiable, Codable {
    let id: Int
    let number: String
    let description: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, number, description
        case createdAt = "created_at"
    }
}

struct Item: Identifiable, Codable {
    let id: Int
    let boxId: Int
    let name: String
    let note: String?
    let photoURL: URL?
    let photoFilename: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case boxId = "box_id"
        case name, note
        case photoURL = "photo_url"
        case createdAt = "created_at"
        case photoFilename = "photo_filename"
    }
}

struct BoxDetail: Codable {
    let id: Int
    let number: String
    let description: String?
    let createdAt: Date
    let items: [Item]?

    enum CodingKeys: String, CodingKey {
        case id, number, description, items
        case createdAt = "created_at"
    }
}
