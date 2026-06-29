import Foundation

extension String {

    /// Cleans the string: removes stop words, special characters, and extra spaces.
    var sanitized: String {
        let stopWords: Set<String> = ["the", "of", "and", "a", "an"]
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !stopWords.contains($0.lowercased()) }
            .joined(separator: " ")
            .lowercased()
    }

    /// Removes dashes, spaces, and punctuation: "Spider-Man" -> "spiderman"
    var condensed: String {
        self.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    /// Splits a string into a title and an issue number after sanitizing.
    /// Returns: (title: "batman", issueNumber: "423")
    func partitionTitleAndIssue() -> (title: String, issueNumber: String?) {
        let clean = self.sanitized

        let pattern = #"(\d+(\.\d+)?)"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: clean, range: NSRange(clean.startIndex..., in: clean)) else {
            return (clean, nil)
        }

        let matchRange = Range(match.range(at: 0), in: clean)!
        let foundNumber = String(clean[matchRange])

        let titlePart = clean.replacingCharacters(in: matchRange, with: "")
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "  ", with: " ")

        return (titlePart, foundNumber)
    }
}
