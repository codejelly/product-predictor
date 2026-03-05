//
//  String+Extension.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/26/26.
//

import Foundation

extension String {
    // separates the query out into a list of individual words
    // removes special charcaters,spaces
    // rejoins the words into a single string
    // all characters lowercase
    var sanitized: String {
        let stopWords: Set<String> = ["the", "of", "and", "a", "an"]
        // Sanitization: components splits it into ["the", ""]
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted)
        // Filter !$0.isEmpty: Removes the empty string $\rightarrow$ ["the"].
            .filter { !$0.isEmpty && !stopWords.contains($0)}
            .joined(separator: " ")
            .lowercased()
            // ... any other cleanup code
    }
}
