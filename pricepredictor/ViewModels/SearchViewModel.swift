//
//  SearchViewModel.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/20/26.
//

// data sent here

import Foundation

@Observable
// example use of observable - Since @Observable tracks every property automatically, the moment you set self.lastSubmittedSearch = query in your ViewModel, the subtitle in your View will update instantly.
class SearchViewModel {
    var errorMessage: String?
    var showAlert: Bool = false // the alert "Trigger"
    var products: [Product] = []
    var isLoading = false
    var searchText = ""
    var lastSubmittedSearch = "" // 👈 ADD THIS: Our "Memory" variable
    
    private let service = ProductService()
    
    func loadData(for query: String) async {
        // Start spinner begins
        isLoading = true
        
        // This code is GUARANTEED to run when the function finishes
        defer { isLoading = false }
        errorMessage = nil
        
        self.lastSubmittedSearch = query
        
        do {
            let data = try await service.fetchProducts(query: query)
            // This line only runs if NO error was thrown above
            self.products = data
            
            let cleansedSearch = query.sanitized
            
            // 1. Break the sanitized query into individual words (tokens)
            let searchTokens = cleansedSearch.components(separatedBy: " ")
                .filter { !$0.isEmpty }
            
            // 2. Logic: If the user submitted a query that resulted in zero valid tokens
                if searchTokens.isEmpty {
                    self.products = []
                    return
                }
            
            let refined = data.filter { product in
                let productName = product.name.sanitized
                
                // 2. The "Strict AND" Check: Does the product name contain EVERY word in the search tokens?
                return searchTokens.allSatisfy { token in
                        productName.contains(token)
                    }
            }
            
            // Only update the UI once with the final, filtered list
            self.products = refined
            // with do catch an error is already expected by default
            // let filtering for specific errors rather than just treating everything as a generic failure.
        } catch let error as ResponseError {
            // 2. This catches the specific error you defined in the Service
            self.products = []
            self.errorMessage = error.errorDecription
            // Setting showAlert = true is the "Flare Gun." Your View sees this flare and immediately pops up the .alert box we coded earlier.
            self.showAlert = true
        } catch {
            // localized catch all
            self.errorMessage = "Unexpected error: \(error.localizedDescription)"
            self.showAlert = true
        }
    }
}
