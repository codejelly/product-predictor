//
//  Product.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/18/26.
//

// Response types returned
// Volumes types requested
// Volumeissues types requested


struct ComicResponse<T: Codable>: Codable {
    // parent container
    let offset: Int
    let numberOfTotalResults: Int
    let results: [T]

    enum CodingKeys: String, CodingKey {
        case offset
        // Map the API's snake_case to your Swift CamelCase
        case numberOfTotalResults = "number_of_total_results"
        // results is the same key ,returns the entirety of the array of data
        // it is considered top level, so need to call it here
        // issue was that we could not make to separate instances of it , return list for Volumes and return list for VolumeIssues
        // results [T] ,when data is availble we will provdie that type
        case results
    }
}

// these structs break down the initial call
struct Volumes: Codable, Identifiable {
    // 1. Give 'id' a unique name for Swift logic, map it to "id" from API
    let id: Int
    let name: String
    let image: ImageLinks?
    // Determine volume size, use for pagination logic
    let countOfIssues: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case image
        case countOfIssues = "count_of_issues"
    }
}

struct VolumeIssues: Codable, Identifiable {
    // 1. Give 'id' a unique name for Swift logic, map it to "id" from API
    let id: Int
    let issueNumber: String
    let name: String?
    let image: ImageLinks?
    let storeDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case image
        case issueNumber = "issue_number"
        case storeDate = "store_date"
    }
        // Calculated property for sorting
            var sortableNumber: Double {
                // Simple logic to convert "1/2" to 0.5 for correct list ordering
                if issueNumber == "1/2" { return 0.5 }
                if issueNumber == "1/4" { return 0.25 }
                // If the character isn't a digit, a decimal point, or a minus sign, throw it away
                // Issue "100A": The filter sees the A, realizes it's not in the "allowed list" (0123456789.-), and deletes it. Result: "100".
                let filtered = issueNumber.filter {"0123456789.-".contains($0)}
                // Without that ?? 0.0, your app would crash or throw an error because it wouldn't know how to turn "nothing" into a number
                return Double(filtered) ?? 0.0
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
