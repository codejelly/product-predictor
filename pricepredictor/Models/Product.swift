//
//  Product.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/18/26.
//

struct ComicResponse: Codable {
    let results: [Product]
    let offset: Int
    let numberOfTotalResults: Int

    enum CodingKeys: String, CodingKey {
        case results, offset
        // Map the API's snake_case to your Swift CamelCase
        case numberOfTotalResults = "number_of_total_results"
    }
}

struct Product: Codable, Identifiable {
    // 1. Give 'id' a unique name for Swift logic, map it to "id" from API
    let id: Int
    let name: String
    let image: ImageLinks

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case image
    }
}

struct ImageLinks: Codable {
    let smallURL: String
    let screenURL: String

    enum CodingKeys: String, CodingKey {
        case smallURL = "small_url"
        case screenURL = "screen_url" // Comic Vine uses 'screen_url' or 'medium_url'
    }
}
