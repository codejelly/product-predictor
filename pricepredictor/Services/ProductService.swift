//
//  ProductService.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/18/26.
//

import Foundation

enum ResponseError: Error {
    case decodingError
    case invalidKey
    case networkError
    case invalidResponse
    case accessDenied
    case rateLimitExceeded
    case serverError(String)
    case invalidUrl

    var errorDecription: String {
        switch self {
        case .invalidUrl:
            return "Invalid URL"
        case .decodingError:
            return "Decoding error"
        case .rateLimitExceeded:
            return "Rate Limit Exceeded"
        case .invalidKey:
            return "Invalid Key"
        case .networkError:
            return "Network Error"
        case .invalidResponse:
            return "Invalid Response"
        case .accessDenied:
            return "Access Denied"
        case .serverError(let message):
            return message
        }
    }
}

class ProductService {

    /// THE HELPER: This handles all the repetitive network logic
    /// // 2.     performRequest: Does the "Driving" (Networking & Decoding).
    private func performRequest<T: Codable>(for url: URL) async throws -> T {
        print("🚀 Network Call: \(url)")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw ResponseError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResponseError.invalidResponse
        }

        // --- THE CONSOLIDATED ERROR HANDLER ---
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                // If you have specific date formats, you'd set them here:
                // decoder.dateDecodingStrategy = .iso8601
                print("Resposne data: \(data)")
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ Decoding Error: \(error)")
                throw ResponseError.decodingError
            }
        case 429:
            throw ResponseError.rateLimitExceeded
        case 401, 403:
            throw ResponseError.invalidKey
        default:
            throw ResponseError.serverError("Error code: \(httpResponse.statusCode)")
        }
    }

    enum Secrets {
        /// Comic Vine key from the app Info.plist (xcconfig at build time), or `COMIC_VINE_API_KEY` in the environment (schemes, previews, CI).
        static var apiKey: String {
            let plistKey = Bundle.main.object(forInfoDictionaryKey: "COMIC_VINE_API_KEY") as? String
            let envKey = ProcessInfo.processInfo.environment["COMIC_VINE_API_KEY"]
            for candidate in [plistKey, envKey] {
                if let raw = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
                    return raw
                }
            }
            fatalError(
                "COMIC_VINE_API_KEY is missing or empty. Add project-root Secrets.xcconfig (copy Secrets.example.xcconfig), " +
                "or set COMIC_VINE_API_KEY in the Run scheme’s Environment Variables. SwiftUI Previews use a different bundle, so the env var is required there."
            )
        }
    }
}

extension ProductService {
    //   1. APIConfig: Builds the "Map" (The URL).
    enum APIConfig {
        // API Config - The Endpoint Enum: Handles the "Where" (the URL, the Method).
        // Comic Vine requires the full path up to the endpoint
        static let baseURL = "https://comicvine.gamespot.com/api"

        static func searchVolume(for query: String) -> URL? {
            // 1. Initialize components with the base path
            var components = URLComponents(string: baseURL)

            // ✅ SWITCH: Change from "/api/search/" to "/api/volumes/"
            // The /volumes/ endpoint is a "telephoto lens"—it only looks at series
            // but gives you much deeper detail (like years and issue counts).
            components?.path = "/api/volumes/"

            // 2. Define specific query parameters for the volumes endpoint
            components?.queryItems = [
                URLQueryItem(name: "api_key", value: Secrets.apiKey),
                URLQueryItem(name: "format", value: "json"),

                // ✅ SWITCH: Use 'filter' instead of 'query' for specific resource endpoints.
                // We use 'name:' as a prefix so it searches specifically for the title.
                URLQueryItem(name: "filter", value: "name:\(query)"),

                // ✅ EXPAND: Add the fields that were missing from the general search
                URLQueryItem(name: "field_list", value: "name,image,id,start_year,count_of_issues")
            ]

            // 3. Return the constructed URL
            return components?.url
        }

        static func searchVolumeIssuesURL(
            for volumeID: Int,
            offset: Int = 0,
            limit: Int = 200,
        ) -> URL? {
            // 1. Initialize components with the base path
            var components = URLComponents(string: baseURL)
            components?.path = "/api/issues/" // Adding the specific search path

            // 2. Define all the specific query parameters Comic Vine expects
            // To get a "Range" of issues, you should use the offset and sort parameters instead of trying to force the range into the filter string.
            components?.queryItems = [
                URLQueryItem(name: "api_key", value: Secrets.apiKey),
                URLQueryItem(name: "format", value: "json"),
                // do not have to specify resource volume, now using filter with knowing the volume id
                // Range will be the comic issues
                // sort=issue_number
                // sort, limit, and offset are top-level parameters. They should not be tucked inside the filter string. Only the volumeID belongs in the filter.
                URLQueryItem(name: "offset", value: "\(offset)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "filter",value:"volume:\(volumeID)"),
                //note: Removed sort by ussye number - The Comic Vine API is sorting issue_number as a String (text) instead of an Integer (number). In string sorting, "10" comes before "2" because "1" comes before "2". This is a common
                URLQueryItem(name: "sort", value: "issue_number:asc"),
                // 🎯 ADDED: description, person_credits, character_credits
                URLQueryItem(name: "field_list", value: "id,name,issue_number,image,cover_date,store_date,description,person_credits,character_credits,site_detail_url")
            ]
            // 3. Return the constructed URL
            return components?.url
        }

        static func searchIssuesURL(
            for volumeID: Int,
            offset: Int = 0,
            limit: Int = 200,
        ) -> URL? {
            // 1. Initialize components with the base path
            var components = URLComponents(string: baseURL)
            components?.path = "/api/issues/" // Adding the specific search path

            // 2. Define all the specific query parameters Comic Vine expects
            // To get a "Range" of issues, you should use the offset and sort parameters instead of trying to force the range into the filter string.
            components?.queryItems = [
                URLQueryItem(name: "api_key", value: Secrets.apiKey),
                URLQueryItem(name: "format", value: "json"),
                // do not have to specify resource volume, now using filter with knowing the volume id
                // Range will be the comic issues
                // sort=issue_number
                // sort, limit, and offset are top-level parameters. They should not be tucked inside the filter string. Only the volumeID belongs in the filter.
                URLQueryItem(name: "offset", value: "\(offset)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
                //note: Removed sort by ussye number - The Comic Vine API is sorting issue_number as a String (text) instead of an Integer (number). In string sorting, "10" comes before "2" because "1" comes before "2". This is a common
                URLQueryItem(name: "sort", value: "issue_number:asc"),
                URLQueryItem(name: "field_list", value: "id,name,issue_number,image,cover_date,store_date")
            ]
            // 3. Return the constructed URL
            return components?.url
        }
    }

    // ** Currently using to fetch Volumes and return all Volume ids within smart search
    func fetchVolumes(for query: String) async throws -> [Volumes] {
        guard let URL =  APIConfig.searchVolume(for: query)
        else { throw ResponseError.invalidUrl }
        let data = try await performRequest(for: URL) as ComicResponse<Volumes>
        // returns a JSON
        return data.results
    }
    // ** Currently using
    // Start Loading → Get Data → Stop Loading.
    // task The Task block allows the button to finish its animation immediately while the network request runs in the background.
    // Added 'offset' parameter to the signature
    func fetchVolumeIssues(for volumeID: Int, offset: Int) async throws -> (issues: [ComicIssues], totalCount: Int) {

        // 1. Pass the offset into your URL builder
        guard let url = APIConfig.searchVolumeIssuesURL(for: volumeID, offset: offset)
        else { throw ResponseError.invalidUrl }

        // 2. Perform the request and decode as your ComicResponse
        let data = try await performRequest(for: url) as ComicResponse<ComicIssues>

        // 3. Log for debugging (Great for SDET verification)
        print("Fetched Volume \(volumeID) at Offset: \(offset). Total: \(data.numberOfTotalResults)")
        print(data.results, data.numberOfTotalResults)
        return (data.results, data.numberOfTotalResults)
    }

    // ** Currently using
    // issue is that Volume name and issue name differ , when query for an issue needs the exact issue name
    func fetchSpecificIssues(title: String, issueNumber: String, offset: Int) async throws -> (issues: [ComicIssues], totalCount: Int) {
        var components = URLComponents(string: "https://comicvine.gamespot.com/api/issues/")

        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Secrets.apiKey),
            URLQueryItem(name: "format", value: "json"),
            // Combine the title and the number in one filter string
            URLQueryItem(name: "filter", value: "name:\(title),issue_number:\(issueNumber)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "field_list", value: "id,name,issue_number,image,store_date,volume")
        ]

        guard let url = components?.url else { throw ResponseError.invalidUrl}

        // Standard URLSession fetch here...
        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedResponse = try JSONDecoder().decode(ComicResponse<ComicIssues>.self, from: data)

        print("Fetched issues", decodedResponse.results)
        return (issues: decodedResponse.results, totalCount: decodedResponse.numberOfTotalResults)
    }

    func fetchIssuesByVolumeID(id: Int, issueNumber: String, offset: Int = 0) async throws -> (issues: [ComicIssues], totalCount: Int) {
        var components = URLComponents(string: "https://comicvine.gamespot.com/api/issues/")
        // 🎯 SURGICAL FILTER:
        // We use the ID directly. No casing issues, no "Spider-man" vs "Spiderman" typos.
        let filterValue = "volume:\(id),issue_number:\(issueNumber)"

        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Secrets.apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "filter", value: filterValue),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "field_list", value: "id,name,issue_number,image,store_date,volume")
        ]

        guard let url = components?.url else { throw ResponseError.invalidUrl }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedResponse = try JSONDecoder().decode(ComicResponse<ComicIssues>.self, from: data)
        
        return (issues: decodedResponse.results, totalCount: decodedResponse.numberOfTotalResults)
    }

    // Inside ProductService.swift
    func fetchIssuesByMultipleIDs(ids: String, issueNumber: String) async throws -> (issues: [ComicIssues], totalCount: Int) {
        var components = URLComponents(string: "https://comicvine.gamespot.com/api/issues/")

        let filterValue = "volume:\(ids),issue_number:\(issueNumber)"

        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Secrets.apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "filter", value: filterValue),
            URLQueryItem(name: "field_list", value: "id,name,issue_number,image,store_date,volume")
        ]

        guard let url = components?.url else { throw ResponseError.invalidUrl }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedResponse = try JSONDecoder().decode(ComicResponse<ComicIssues>.self, from: data)

        // ✅ Return both the results AND the total count
        return (issues: decodedResponse.results, totalCount: decodedResponse.numberOfTotalResults)
    }
}
