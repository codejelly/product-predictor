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

    /// Splits a string into a title and an issue number.
    /// Returns: (title: "batman", issue: "423")
    func partitionTitleAndIssue() -> (title: String, issueNumber: String?) {
        // 1. Sanitize the string first to ensure we have clean "signal"
        let clean = self.sanitized

        // 2. Regex to find the first sequence of digits
        let pattern = #"(\d+(\.\d+)?)"# // Supports "1" and "12.1"

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: clean, range: NSRange(clean.startIndex..., in: clean)) else {
            return (clean, nil)
        }

        let matchRange = Range(match.range(at: 0), in: clean)!
        let foundNumber = String(clean[matchRange])

        // 3. Title is everything except that number
        let titlePart = clean.replacingCharacters(in: matchRange, with: "")
                             .trimmingCharacters(in: .whitespaces)
                             .replacingOccurrences(of: "  ", with: " ")
        print(titlePart)
        return (titlePart, foundNumber)
    }
}
