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
        static var apiKey: String {
            // This looks into the Info.plist, which was populated in the .xcconfig
            guard let key = Bundle.main.object(forInfoDictionaryKey: "COMIC_VINE_API_KEY") as? String else {
                // We use fatalError here because if the key is missing, the app cannot function.
                fatalError("API_KEY not found in Info.plist / xcconfig")
            }
            return key
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
            components?.path = "/api/search/" // /api/search/ endpoint is like a "wide-angle lens"—it scans the entire Comic Vine database to find any Volume that matches that text.

            // 2. Define all the specific query parameters Comic Vine expects
            components?.queryItems = [
                URLQueryItem(name: "api_key", value: Secrets.apiKey),
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "resources", value: "volume"),
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "field_list", value: "name,image,id")
            ]
            // 3. Return the constructed URL
            return components?.url
        }

        static func searchVolumeIssuesURL(
            for volumeID: Int,
            offset: Int = 0,
            limit: Int = 30
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
                URLQueryItem(name: "sort", value: "issue_number:asc"),
                URLQueryItem(name: "field_list", value: "id,name,issue_number,image,store_date")
            ]
            // 3. Return the constructed URL
            return components?.url
        }
    }

    func fetchVolumes(for query: String) async throws -> [Volumes] {
       guard let URL =  APIConfig.searchVolume(for: query)
        else { throw ResponseError.invalidUrl }
        let data = try await performRequest(for: URL) as ComicResponse<Volumes>
        // returns a JSON
        return data.results
    }
    // Start Loading → Get Data → Stop Loading.
    // task The Task block allows the button to finish its animation immediately while the network request runs in the background.
    func fetchVolumeIssues(for volumeID: Int) async throws -> (issues: [VolumeIssues], totalCount: Int) {
        // 1. Make sure this points to the ISSUES endpoint for a specific Volume ID
        guard let URL = APIConfig.searchVolumeIssuesURL(for: volumeID)
        else { throw ResponseError.invalidUrl }

        // 2. Decode specifically as VolumeIssues
        let data = try await performRequest(for: URL) as ComicResponse<VolumeIssues>
        print("Results: \(data)")

        // need to return results for the body and the header (total resulsts count)
        return (data.results, data.numberOfTotalResults)
    }
}
