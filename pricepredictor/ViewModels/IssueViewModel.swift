// IssueViewModel.swift stays as the "Specialist" that handles de-duping and sorting large lists of issues.

import Foundation

@Observable
class IssueViewModel {
    var issues: [ComicIssues] = []
    var totalResultCount: Int = 0
    var isLoading: Bool = false
    var errorMessage: String?

    private let limit = 100
    private let service = ProductService()

    /// Mode 1: Fetch every issue in a SPECIFIC volume (triggered by tapping a volume)
    func loadEntireVolume(for volumeId: Int) async {
        await executeFetch { offset in
            // Corrected: Uses the Volume ID to get all its issues
            try await self.service.fetchVolumeIssues(for: volumeId, offset: offset)
        }
    }

    /// Mode 2: Search for an issue number across all series
    func searchSpecificIssues(title: String, issueNumber: String) async {
        await executeFetch { offset in
            try await self.service.fetchSpecificIssues(title: title, issueNumber: issueNumber, offset: offset)
        }
    }

    /// The Engine: Handles de-duping, sorting, and pagination
    private func executeFetch(fetchBlock: @escaping (Int) async throws -> (issues: [ComicIssues], totalCount: Int)) async {
        isLoading = true
        issues = []
        var seenIDs = Set<Int>()
        var currentOffset = 0
        var totalToFetch = 1

        do {
            while currentOffset < totalToFetch {
                try Task.checkCancellation()
                let result = try await fetchBlock(currentOffset)

                self.totalResultCount = result.totalCount
                totalToFetch = result.totalCount

                let uniqueNewIssues = result.issues.filter { newIssue in
                    if seenIDs.contains(newIssue.id) { return false }
                    seenIDs.insert(newIssue.id)
                    return true
                }

                self.issues.append(contentsOf: uniqueNewIssues)

                // Sort by issue number
                self.issues.sort { (a, b) -> Bool in
                    let n1 = Int(a.issueNumber.filter { $0.isNumber }) ?? 0
                    let n2 = Int(b.issueNumber.filter { $0.isNumber }) ?? 0
                    return n1 != n2 ? n1 < n2 : a.issueNumber.localizedStandardCompare(b.issueNumber) == .orderedAscending
                }
                currentOffset += limit
            }
        } catch {
            print("Issue Sync Error: \(error)")
        }
        isLoading = false
    }

    @MainActor
    func loadBulkIssues(ids: String, number: String) async {
        self.isLoading = true

        do {
            // This calls the ProductService function you just moved!
            let (fetchedIssues, total) = try await service.fetchIssuesByMultipleIDs(ids: ids, issueNumber: number)

            // Save the results so the SwiftUI List can see them
            self.issues = fetchedIssues
            self.totalResultCount = total
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
}
