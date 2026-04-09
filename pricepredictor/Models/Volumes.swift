//
//  Product.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/18/26.
//

// Response types returned
// Volumes types requested
// Volumeissues types requested

import Foundation

// 1. GENERIC WRAPPER (Stays generic for any T)
struct ComicResponse<T: Codable>: Codable {
    let offset: Int
    let numberOfTotalResults: Int
    let results: [T]
    
    enum CodingKeys: String, CodingKey {
        case offset
        case numberOfTotalResults = "number_of_total_results"
        case results
    }
}

struct Volumes: Identifiable, Codable, Hashable {
    let id: Int
    let startYear: String?
    let countOfIssues: Int?
    let image: ImageLinks?
    let name: String?

    // Custom CodingKeys to match the API's snake_case
    enum CodingKeys: String, CodingKey {
        case id, image
        case startYear = "start_year"
        case countOfIssues = "count_of_issues"
        case name
    }

    // ✅ Manually recreate the "Label" string
    var displayLabel: String {
        let year = startYear ?? "Unknown Year"
        let count = countOfIssues ?? 0
        return "Volume \(year) (\(count) issues)"
    }
}

// 3. VOLUME ISSUES
struct ComicIssues: Codable, Identifiable, Hashable {
    let id: Int
    let issueNumber: String // Keeping as non-optional if you're sure it exists
    let name: String?
    let image: ImageLinks?
    let storeDate: String?
    let coverDate: String?
    let volume: VolumeReference?
    let resourceType: String?
    let description: String?
    let personCredits: [Person]?
    let characterCredits: [Entity]?
    let siteDetailUrl: String?        // 👈 Added for "View on ComicVine" button

    enum CodingKeys: String, CodingKey {
        case id, image, volume, description
        case name // name same key for volumes and comic issues
        case issueNumber = "issue_number"
        case storeDate = "store_date"
        case coverDate = "cover_date"
        case resourceType = "resource_type"
        case personCredits = "person_credits"
        case characterCredits = "character_credits"
        case siteDetailUrl = "site_detail_url"
    }

    // Found in the character_credits, team_credits, or location_credits arrays.
    // Batman, Catwoman, The Riddler.
    struct Entity: Codable, Hashable, Identifiable {
        let id: Int
        let name: String?
    }

    // Creators
    struct Person: Codable, Hashable, Identifiable {
        let id: Int
        let name: String?
        let role: String?
    }

    // ✅ The Modern Sieve Logic
    var sortableNumber: Double {
        if issueNumber == "1/2" { return 0.5 }
        if issueNumber == "1/4" { return 0.25 }

        let scanner = Scanner(string: issueNumber)
        // Corrected for iOS 13+ modern API
        return scanner.scanDouble() ?? 0.0
    }

    var sortingDate: String {
        return storeDate ?? coverDate ?? "1900-01-01"
    }

    // Minimal struct to catch the volume name
    struct VolumeReference: Codable, Hashable {
        let name: String? // This will be "Absolute Batman"
    }
}

// 4. SHARED IMAGE LINKS
struct ImageLinks: Codable, Hashable {
    let smallURL: String?
    let screenURL: String?

    enum CodingKeys: String, CodingKey {
        case smallURL = "small_url"
        case screenURL = "screen_url"
    }
}
