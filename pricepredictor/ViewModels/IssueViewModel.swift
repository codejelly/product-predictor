//
//  IssueViewModel.swift
//  pricepredictor
//
//  Created by matthew chadwell on 3/16/26.
//
import Foundation

@Observable
class IssueViewModel {
    var issues: [VolumeIssues] = []
    var isLoading = false
    private let service = ProductService() // Your existing service
    var totalResultCount: Int = 0

    func loadIssues(for volumeId: Int) async {
        isLoading = true

        // This hits the /issues endpoint filtered by the volume_id
        // We use the same ComicResponse envelope but with VolumeIssues type
        do {
            let fetchedIssues = try await service.fetchVolumeIssues(for: volumeId)
            self.issues = fetchedIssues.issues
            self.totalResultCount = fetchedIssues.totalCount
        } catch {
            print("Sieve Error: \(error)")
        }
        isLoading = false
    }
}
