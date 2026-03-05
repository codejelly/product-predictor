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

    enum APIConfig {
        // Comic Vine requires the full path up to the endpoint
        static let baseURL = "https://comicvine.gamespot.com/api"

        static func searchURL(for query: String) -> URL? {
            // 1. Initialize components with the base path
            var components = URLComponents(string: baseURL)
            components?.path = "/api/search/" // Adding the specific search path

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
    }

    func fetchProducts(query: String) async throws -> [Product] {
        let sanitizedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = APIConfig.searchURL(for: sanitizedQuery)
        // The Physical Connection
        let data: Data
        let response: URLResponse

        guard let url = APIConfig.searchURL(for: query) else {
            throw ResponseError.invalidUrl
        }

        print("🚀 Network Call: \(url)")

        // 1. If a URL session can not be established most likely offline/airplane mode.
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw ResponseError.networkError
        }

        // 2. Check if the response is valid HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResponseError.invalidResponse
        }

        // 3. Debug: Log the essentials
        print("🌐 URL: \(httpResponse.url?.absoluteString ?? "Unknown URL")")
        print("📊 Status Code: \(httpResponse.statusCode)")

        // 4. Debug: See the Raw JSON (The "Box" contents)
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Raw JSON: \(jsonString)")
        }

        // 5. Identify the specific error by status code
        switch httpResponse.statusCode {
        case 200...299:
            // Now it's safe to decode.
            // Take this text and turn it into a List of Product structs
            // Swift automatically maps the keys from the API to your variables
            // If you only use JSONDecoder().decode(...), your app will often "crash" into the catch block with a generic "Data Corrupted" or "Key Not Found" error. This happens because the API is sending you an error message (like "Rate Limit Reached"), but your code is trying to force that message into your Product model.
            do {
                let response = try JSONDecoder().decode(ComicResponse.self, from: data)
                return response.results
            } catch let DecodingError.keyNotFound(key, context) {
                print("❌ Missing Key: \(key.stringValue) — \(context.debugDescription)")
                throw ResponseError.decodingError
            } catch let DecodingError.typeMismatch(type, context) {
                print("❌ Type Mismatch: \(type) — \(context.debugDescription)")
                throw ResponseError.decodingError
            } catch {
                print("❌ General Decoding Error: \(error)")
                throw ResponseError.decodingError
            }
        case 429:
            // This identifies your 200-call daily limit!
            throw ResponseError.rateLimitExceeded
        case 401, 403:
            throw ResponseError.invalidKey // Specific: Your API key is wrong or expired.
        default:
            // Catch-all for other server issues (500, 404, etc.)
            throw ResponseError.serverError("Error code: \(httpResponse.statusCode)")
        }
    }
}
